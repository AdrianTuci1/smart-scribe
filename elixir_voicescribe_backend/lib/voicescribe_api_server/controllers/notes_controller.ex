defmodule VoiceScribeAPIServer.NotesController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  def create(conn, params) do
    note_id = Map.get(params, "id")
    user_id = conn.assigns.current_user
    case DynamoDBRepo.create_note(user_id, note_id, params) do
      {:ok, _} -> json(conn, %{status: "ok"})
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

  defp decode_item(item), do: ExAws.Dynamo.decode_item(item)
end
