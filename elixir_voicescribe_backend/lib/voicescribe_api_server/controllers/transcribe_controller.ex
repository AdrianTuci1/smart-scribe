defmodule VoiceScribeAPIServer.TranscribeController do
  use VoiceScribeAPIServer, :controller
  require Logger

  alias VoiceScribeAPI.Transcription.TranscribeSessionManager

  def start_session(conn, %{"user_id" => user_id}) do
    case TranscribeSessionManager.start_session(user_id) do
      {:ok, session_id} ->
        json(conn, %{status: "ok", session_id: session_id})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{status: "error", message: "Failed to start session: #{inspect(reason)}"})
    end
  end

  def upload_chunk(conn, %{"user_id" => user_id, "chunk" => chunk_data}) do
    case TranscribeSessionManager.add_chunk(user_id, chunk_data) do
      :ok ->
        json(conn, %{status: "ok", message: "Chunk received"})

      {:error, :session_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{status: "error", message: "Session not found"})

      {:error, :session_not_recording} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: "Session is not in recording state"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{status: "error", message: "Failed to add chunk: #{inspect(reason)}"})
    end
  end

  def finish_session(conn, %{"user_id" => user_id}) do
    case TranscribeSessionManager.finish_session(user_id) do
      {:ok, :processing} ->
        json(conn, %{status: "ok", message: "Processing transcription"})

      {:error, :session_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{status: "error", message: "Session not found"})

      {:error, :session_not_recording} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: "Session is not in recording state"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{status: "error", message: "Failed to finish session: #{inspect(reason)}"})
    end
  end

  def get_status(conn, %{"user_id" => user_id}) do
    case TranscribeSessionManager.get_session_status(user_id) do
      {:ok, session_data} ->
        response = %{
          status: "ok",
          session: %{
            session_id: session_data.session_id,
            status: session_data.status,
            created_at: session_data.created_at,
            completed_at: session_data.completed_at,
            result: session_data.result,
            error: session_data.error
          }
        }
        json(conn, response)

      {:error, :session_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{status: "error", message: "Session not found"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{status: "error", message: "Failed to get session: #{inspect(reason)}"})
    end
  end
end
