defmodule VoiceScribeAPIServer.NotesController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  def create(conn, params) do
    note_id = Map.get(params, "id") || UUID.uuid4() |> to_string()
    user_id = conn.assigns.current_user

    # Add timestamp if not present
    note_data = case Map.get(params, "timestamp") do
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

  def list(conn, _params) do
    user_id = conn.assigns.current_user
    case DynamoDBRepo.list_notes(user_id) do
      {:ok, result} ->
        items = (result["Items"] || []) |> Enum.map(&decode_item/1)
        json(conn, %{data: items})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
      error ->
        # Handle any other error cases
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to fetch notes"})
    end
  end

  def delete(conn, %{"id" => note_id}) do
    user_id = conn.assigns.current_user
    case DynamoDBRepo.delete_note(user_id, note_id) do
       {:ok, _} -> json(conn, %{status: "ok"})
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
      decoded_value = case value do
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
