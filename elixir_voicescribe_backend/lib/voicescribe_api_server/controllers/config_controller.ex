defmodule VoiceScribeAPIServer.ConfigController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo
  alias VoiceScribeAPI.AI.BedrockClient

  def get_config(conn, params) do
    # Extract type from params or use default based on path
    type = Map.get(params, "type", get_default_type_from_path(conn.request_path))

    # Params
    page = Map.get(params, "page", "1") |> String.to_integer()
    limit = Map.get(params, "limit", "20") |> String.to_integer()
    search = Map.get(params, "search", "") |> String.downcase()
    sort = Map.get(params, "sort", "newest")

    user_id = conn.assigns.current_user

    # Use the repository to get config which handles decoding properly
    case DynamoDBRepo.get_config(user_id, type) do
      empty_map when empty_map == %{} ->
        case type do
          "dictionary" -> json(conn, %{data: [], meta: %{has_more: false, total: 0}})
          "snippets" -> json(conn, %{data: [], meta: %{has_more: false, total: 0}})
          _ -> json(conn, %{data: nil})
        end

      config_data ->
        case type do
          "dictionary" ->
            entries = Map.get(config_data, "entries", [])

            # Filter
            filtered =
              if search == "" do
                entries
              else
                Enum.filter(entries, fn e ->
                  inc = Map.get(e, "incorrectWord", "") || ""
                  cor = Map.get(e, "correctWord", "") || ""

                  String.contains?(String.downcase(inc), search) or
                    String.contains?(String.downcase(cor), search)
                end)
              end

            # Sort (Dictionary: alphabetical by incorrectWord usually makes sense as default, but adhering to requested sorts)
            # User asked for "newest, oldest, alphabetical".
            # Dictionary might not have timestamps?
            # Schema says "createdAt" added in put_dictionary_entry.
            sorted =
              case sort do
                # Safety if nil?
                "newest" ->
                  Enum.sort_by(filtered, & &1["createdAt"], {:desc, Date})
                  # Actually, check if createdAt exists. If not, fallback.
                  Enum.sort_by(filtered, fn e -> Map.get(e, "createdAt") || "" end, :desc)

                "oldest" ->
                  Enum.sort_by(filtered, fn e -> Map.get(e, "createdAt") || "" end, :asc)

                "alphabetical" ->
                  Enum.sort_by(
                    filtered,
                    fn e -> String.downcase(Map.get(e, "incorrectWord") || "") end,
                    :asc
                  )

                _ ->
                  Enum.sort_by(filtered, fn e -> Map.get(e, "createdAt") || "" end, :desc)
              end

            # Paginate
            count = length(sorted)
            offset = (page - 1) * limit
            paginated = Enum.slice(sorted, offset, limit)
            has_more = offset + limit < count

            json(conn, %{data: paginated, meta: %{has_more: has_more, total: count, page: page}})

          "snippets" ->
            snippets = Map.get(config_data, "snippets", [])

            filtered =
              if search == "" do
                snippets
              else
                Enum.filter(snippets, fn s ->
                  title = Map.get(s, "title", "") || ""
                  content = Map.get(s, "content", "") || ""

                  String.contains?(String.downcase(title), search) or
                    String.contains?(String.downcase(content), search)
                end)
              end

            sorted =
              case sort do
                # Assuming snippets have createdAt
                "newest" ->
                  Enum.sort_by(filtered, fn s -> Map.get(s, "createdAt") || "" end, :desc)

                "oldest" ->
                  Enum.sort_by(filtered, fn s -> Map.get(s, "createdAt") || "" end, :asc)

                "alphabetical" ->
                  Enum.sort_by(
                    filtered,
                    fn s -> String.downcase(Map.get(s, "title") || "") end,
                    :asc
                  )

                _ ->
                  Enum.sort_by(filtered, fn s -> Map.get(s, "createdAt") || "" end, :desc)
              end

            count = length(sorted)
            offset = (page - 1) * limit
            paginated = Enum.slice(sorted, offset, limit)
            has_more = offset + limit < count

            json(conn, %{data: paginated, meta: %{has_more: has_more, total: count, page: page}})

          _ ->
            json(conn, %{data: config_data})
        end
    end
  end

  def put_config(conn, params) do
    # Extract type from params or use default based on path
    type = Map.get(params, "type", get_default_type_from_path(conn.request_path))

    user_id = conn.assigns.current_user

    case DynamoDBRepo.put_config(user_id, type, params) do
      {:ok, _} -> json(conn, %{status: "ok"})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  # Granular Dictionary
  def add_dictionary_entry(conn, %{"entry" => entry}) do
    modify_config_list(conn, "dictionary", "entries", :add, entry)
  end

  def update_dictionary_entry(conn, %{"entry" => entry}) do
    modify_config_list(conn, "dictionary", "entries", :update, entry)
  end

  def delete_dictionary_entry(conn, %{"id" => id}) do
    modify_config_list(conn, "dictionary", "entries", :delete, id)
  end

  # Granular Snippets
  def add_snippet(conn, %{"snippet" => snippet}) do
    modify_config_list(conn, "snippets", "snippets", :add, snippet)
  end

  def update_snippet(conn, %{"snippet" => snippet}) do
    modify_config_list(conn, "snippets", "snippets", :update, snippet)
  end

  def delete_snippet(conn, %{"id" => id}) do
    modify_config_list(conn, "snippets", "snippets", :delete, id)
  end

  defp modify_config_list(conn, type, list_key, action, payload) do
    user_id = conn.assigns.current_user
    current_config = DynamoDBRepo.get_config(user_id, type)
    list = Map.get(current_config, list_key, [])

    new_list =
      case action do
        :add ->
          # Ensure ID
          item = Map.put_new(payload, "id", UUID.uuid4())
          # Ensure createdAt
          item = Map.put_new(item, "createdAt", DateTime.utc_now() |> DateTime.to_iso8601())
          # Dictionary usually uses 'incorrectWord', Snippets 'createdAt' for sort?
          # Just append/prepend.
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
        "dictionary" -> BedrockClient.save_dictionary(user_id, new_list)
        "snippets" -> BedrockClient.save_snippets(user_id, new_list)
        _ -> {:error, "Unknown type"}
      end

    case result do
      {:ok, _} -> json(conn, %{success: true})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  # New endpoints for dictionary and style preferences
  def save_dictionary(conn, %{"dictionary" => dictionary}) do
    entries = Map.get(dictionary, "entries", [])
    user_id = conn.assigns.current_user

    case BedrockClient.save_dictionary(user_id, entries) do
      {:ok, _} -> json(conn, %{status: "ok"})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  def save_style_preferences(conn, %{"preferences" => preferences}) do
    context = Map.get(preferences, "context", "No specific context")
    style = Map.get(preferences, "style", "No specific style")
    user_id = conn.assigns.current_user

    case BedrockClient.save_style_preferences(user_id, context, style) do
      {:ok, _} -> json(conn, %{status: "ok"})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  def save_snippets(conn, %{"snippets" => snippets}) do
    user_id = conn.assigns.current_user

    case BedrockClient.save_snippets(user_id, snippets) do
      {:ok, _} -> json(conn, %{status: "ok"})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  # Helper function to determine type from request path
  defp get_default_type_from_path("/api/v1/config/snippets"), do: "snippets"
  defp get_default_type_from_path("/api/v1/config/dictionary"), do: "dictionary"
  defp get_default_type_from_path("/api/v1/config/settings"), do: "settings"
  defp get_default_type_from_path("/api/v1/config/onboarding"), do: "onboarding"
  defp get_default_type_from_path("/api/v1/config/style_preferences"), do: "style_preferences"
  defp get_default_type_from_path(_), do: "unknown"
end
