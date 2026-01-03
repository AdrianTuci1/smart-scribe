defmodule VoiceScribeAPIServer.NotesController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  def create(conn, params) do
    note_id = Map.get(params, "id") || UUID.uuid4() |> to_string()
    user_id = conn.assigns.current_user

    # Add timestamp if not present
    note_data =
      case Map.get(params, "timestamp") do
        nil -> Map.put(params, "timestamp", DateTime.utc_now() |> DateTime.to_iso8601())
        _ -> params
      end

    case DynamoDBRepo.create_note(user_id, note_id, note_data) do
      {:ok, _} ->
        # Return the created note with its ID
        created_note = Map.put(note_data, "id", note_id)
        json(conn, created_note)

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  def list(conn, params) do
    user_id = conn.assigns.current_user

    # pagination params
    page = Map.get(params, "page", "1") |> String.to_integer()
    limit = Map.get(params, "limit", "20") |> String.to_integer()
    search = Map.get(params, "search", "") |> String.downcase()
    sort = Map.get(params, "sort", "newest")

    # Fetch ALL notes to allow for "backend" search/sort without GSI
    # This is acceptable for expected data volume (<5000 items)
    notes =
      DynamoDBRepo.list_all_notes(user_id)
      |> Enum.map(&decode_item/1)

    # Filter
    filtered =
      if search == "" do
        notes
      else
        Enum.filter(notes, fn note ->
          content = Map.get(note, "content", "") || ""
          String.contains?(String.downcase(content), search)
        end)
      end

    # Sort
    sorted =
      case sort do
        "oldest" -> Enum.sort_by(filtered, &(&1["timestamp"] || &1["updatedAt"]), :asc)
        "alphabetical" -> Enum.sort_by(filtered, &String.downcase(&1["content"] || ""), :asc)
        # newest default
        _ -> Enum.sort_by(filtered, &(&1["timestamp"] || &1["updatedAt"]), :desc)
      end

    # Paginate
    total_count = length(sorted)
    offset = (page - 1) * limit
    paginated = Enum.slice(sorted, offset, limit)

    has_more = offset + limit < total_count

    json(conn, %{
      data: paginated,
      meta: %{
        has_more: has_more,
        total: total_count,
        page: page,
        limit: limit
      }
    })
  end

  def delete(conn, %{"id" => note_id}) do
    user_id = conn.assigns.current_user

    case DynamoDBRepo.delete_note(user_id, note_id) do
      {:ok, _} ->
        json(conn, %{status: "ok"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  defp decode_item(item) do
    try do
      ExAws.Dynamo.decode_item(item)
    rescue
      _ ->
        # If decoding fails, try manual decoding
        decode_dynamo_item(item)
    end
  end

  # Helper function to manually decode DynamoDB item format
  defp decode_dynamo_item(item) when is_map(item) do
    Enum.reduce(item, %{}, fn {key, value}, acc ->
      decoded_value =
        case value do
          %{"S" => string} -> string
          %{"N" => number} -> number
          %{"L" => list} -> decode_dynamo_list(list)
          %{"M" => nested_map} -> decode_dynamo_item(nested_map)
          _ -> value
        end

      Map.put(acc, key, decoded_value)
    end)
  end

  defp decode_dynamo_item(item), do: item

  # Helper function to decode DynamoDB list format
  defp decode_dynamo_list(items) when is_list(items) do
    Enum.map(items, fn item ->
      case item do
        %{"S" => string} -> string
        %{"N" => number} -> number
        %{"L" => list} -> decode_dynamo_list(list)
        %{"M" => nested_map} -> decode_dynamo_item(nested_map)
        _ -> item
      end
    end)
  end

  defp decode_dynamo_list(_), do: []
end
