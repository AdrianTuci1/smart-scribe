defmodule VoiceScribeAPIServer.TeamController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  # GET /team/members
  def index(conn, _params) do
    user_id = conn.assigns.current_user

    # 1. Get User's Team ID
    case DynamoDBRepo.get_config(user_id, "settings") do
      %{"teamId" => team_id} when is_binary(team_id) ->
        # 2. Get Team Metadata (members list)
        case DynamoDBRepo.get_config("TEAM_" <> team_id, "metadata") do
          %{"members" => members} ->
            json(conn, %{members: members})

          _ ->
            # Fallback if team metadata missing, return just self or empty
            json(conn, %{members: []})
        end

      _ ->
        json(conn, %{members: []})
    end
  end

  # POST /team/invite
  def invite(conn, %{"email" => email}) do
    user_id = conn.assigns.current_user

    # Logic:
    # 1. Check if user belongs to a team. If not, create one.
    # 2. Generate invite link/code (reuse invitation logic or simplified).
    # 3. For MVP, we might just "mock" the invite or create a pending invitation record.

    # Let's ensure user has a teamId
    settings = DynamoDBRepo.get_config(user_id, "settings")
    team_id = Map.get(settings, "teamId")

    team_id =
      if is_nil(team_id) do
        # Create new Team
        new_id = UUID.uuid4()
        # Update User
        new_settings = Map.put(settings, "teamId", new_id)
        DynamoDBRepo.put_config(user_id, "settings", new_settings)

        # Initialize Team Metadata
        DynamoDBRepo.put_config("TEAM_" <> new_id, "metadata", %{
          "members" => [
            %{"email" => "current_user_placeholder", "status" => "active", "id" => user_id}
          ],
          "ownerId" => user_id
        })

        new_id
      else
        team_id
      end

    # Create Invitation Record (reusing existing mechanism or simplified)
    # New Logic: Check if user exists, then send Notification
    case DynamoDBRepo.get_user_by_email(email) do
      {:ok, invitee_id} ->
        if invitee_id == user_id do
          conn |> put_status(:bad_request) |> json(%{error: "Cannot invite yourself"})
        else
          # Create Notification for invitee
          DynamoDBRepo.create_notification(
            invitee_id,
            "Team Invitation",
            "You have been invited to join a team.",
            "team_invite",
            %{teamId: team_id, inviterId: user_id}
          )

          json(conn, %{message: "Invitation sent to #{email}"})
        end

      _ ->
        conn |> put_status(:not_found) |> json(%{error: "User with email #{email} not found"})
    end
  end

  alias VoiceScribeAPI.AI.BedrockClient

  # GET /team/shared/:type (type = snippets | dictionary)
  def shared_items(conn, params) do
    type = Map.get(params, "type")

    # Params
    page = Map.get(params, "page", "1") |> String.to_integer()
    limit = Map.get(params, "limit", "20") |> String.to_integer()
    search = Map.get(params, "search", "") |> String.downcase()
    sort = Map.get(params, "sort", "newest")

    user_id = conn.assigns.current_user

    case DynamoDBRepo.get_config(user_id, "settings") do
      %{"teamId" => team_id} when is_binary(team_id) ->
        # Fetch from Team Partition
        # This returns the raw map %{"entries" => [...]} or %{"snippets" => [...]}
        team_config_raw = DynamoDBRepo.get_config("TEAM_" <> team_id, type)

        # We need to replicate logic from ConfigController for filtering/sorting
        # decode not needed if get_config returns map?
        config_data = team_config_raw
        # DynamoDBRepo.get_config returns map.

        case type do
          "dictionary" ->
            entries = Map.get(config_data, "entries", [])
            filtered = filter_dictionary(entries, search)
            sorted = sort_items(filtered, sort, "incorrectWord")
            paginated_response(conn, sorted, page, limit)

          "snippets" ->
            snippets = Map.get(config_data, "snippets", [])
            filtered = filter_snippets(snippets, search)
            sorted = sort_items(filtered, sort, "title")
            paginated_response(conn, sorted, page, limit)

          _ ->
            json(conn, %{data: [], meta: %{total: 0}})
        end

      _ ->
        json(conn, %{data: [], meta: %{total: 0}})
    end
  end

  # Helper functions duplicating ConfigController logic (should extract later)
  defp filter_dictionary(entries, "") do
    entries
  end

  defp filter_dictionary(entries, search) do
    Enum.filter(entries, fn e ->
      inc = Map.get(e, "incorrectWord", "") || ""
      cor = Map.get(e, "correctWord", "") || ""

      String.contains?(String.downcase(inc), search) or
        String.contains?(String.downcase(cor), search)
    end)
  end

  defp filter_snippets(snippets, "") do
    snippets
  end

  defp filter_snippets(snippets, search) do
    Enum.filter(snippets, fn s ->
      title = Map.get(s, "title", "") || ""
      content = Map.get(s, "content", "") || ""

      String.contains?(String.downcase(title), search) or
        String.contains?(String.downcase(content), search)
    end)
  end

  defp sort_items(items, sort, alpha_field) do
    case sort do
      "newest" ->
        Enum.sort_by(items, fn i -> Map.get(i, "createdAt") || "" end, :desc)

      "oldest" ->
        Enum.sort_by(items, fn i -> Map.get(i, "createdAt") || "" end, :asc)

      "alphabetical" ->
        Enum.sort_by(items, fn i -> String.downcase(Map.get(i, alpha_field) || "") end, :asc)

      _ ->
        items
    end
  end

  defp paginated_response(conn, list, page, limit) do
    count = length(list)
    offset = (page - 1) * limit
    paginated = Enum.slice(list, offset, limit)
    has_more = offset + limit < count
    json(conn, %{data: paginated, meta: %{has_more: has_more, total: count, page: page}})
  end

  # Granular Team Updates
  def add_shared_item(conn, %{"type" => type, "item" => item}) do
    modify_team_list(conn, type, :add, item)
  end

  def update_shared_item(conn, %{"type" => type, "item" => item}) do
    modify_team_list(conn, type, :update, item)
  end

  def delete_shared_item(conn, %{"type" => type, "id" => id}) do
    modify_team_list(conn, type, :delete, id)
  end

  # POST /team/shared/:type (Legacy overwrite - Keep for safety but deprecated)
  def update_shared_items(conn, %{"type" => type, "data" => data}) do
    user_id = conn.assigns.current_user

    case DynamoDBRepo.get_config(user_id, "settings") do
      %{"teamId" => team_id} when is_binary(team_id) ->
        if type in ["snippets", "dictionary"] do
          # Use BedrockClient to save correct format
          target_id = "TEAM_" <> team_id

          result =
            case type do
              "dictionary" -> BedrockClient.save_dictionary(target_id, data)
              "snippets" -> BedrockClient.save_snippets(target_id, data)
            end

          case result do
            {:ok, _} -> json(conn, %{success: true})
            {:error, r} -> json(conn, %{error: inspect(r)})
          end
        else
          conn |> put_status(:bad_request) |> json(%{error: "Invalid type"})
        end

      _ ->
        conn |> put_status(:forbidden) |> json(%{error: "User not in a team"})
    end
  end

  defp modify_team_list(conn, type, action, payload) do
    user_id = conn.assigns.current_user

    case DynamoDBRepo.get_config(user_id, "settings") do
      %{"teamId" => team_id} when is_binary(team_id) ->
        target_id = "TEAM_" <> team_id

        list_key = if type == "dictionary", do: "entries", else: "snippets"
        current_config = DynamoDBRepo.get_config(target_id, type)
        list = Map.get(current_config, list_key, [])

        new_list =
          case action do
            :add ->
              item = Map.put_new(payload, "id", UUID.uuid4())
              item = Map.put_new(item, "createdAt", DateTime.utc_now() |> DateTime.to_iso8601())
              [item | list]

            :update ->
              Enum.map(list, fn item ->
                if item["id"] == payload["id"], do: payload, else: item
              end)

            :delete ->
              Enum.reject(list, fn item -> item["id"] == payload end)
          end

        result =
          case type do
            "dictionary" -> BedrockClient.save_dictionary(target_id, new_list)
            "snippets" -> BedrockClient.save_snippets(target_id, new_list)
            _ -> {:error, "Invalid type"}
          end

        case result do
          {:ok, _} -> json(conn, %{success: true})
          {:error, reason} -> json(conn, %{error: inspect(reason)})
        end

      _ ->
        conn |> put_status(:forbidden) |> json(%{error: "User not in a team"})
    end
  end
end
