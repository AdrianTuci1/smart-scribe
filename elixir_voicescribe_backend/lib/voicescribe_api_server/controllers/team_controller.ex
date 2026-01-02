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

  # GET /team/shared/:type (type = snippets | dictionary)
  def shared_items(conn, %{"type" => type}) do
    user_id = conn.assigns.current_user

    case DynamoDBRepo.get_config(user_id, "settings") do
      %{"teamId" => team_id} when is_binary(team_id) ->
        # Fetch from Team Partition
        items = DynamoDBRepo.get_config("TEAM_" <> team_id, type)
        json(conn, items)

      _ ->
        json(conn, %{})
    end
  end

  # POST /team/shared/:type
  def update_shared_items(conn, %{"type" => type, "data" => data}) do
    user_id = conn.assigns.current_user

    case DynamoDBRepo.get_config(user_id, "settings") do
      %{"teamId" => team_id} when is_binary(team_id) ->
        # Update Team Partition
        # Validate type to be safe
        if type in ["snippets", "dictionary"] do
          DynamoDBRepo.put_config("TEAM_" <> team_id, type, data)
          json(conn, %{success: true})
        else
          conn |> put_status(:bad_request) |> json(%{error: "Invalid type"})
        end

      _ ->
        conn |> put_status(:forbidden) |> json(%{error: "User not in a team"})
    end
  end
end
