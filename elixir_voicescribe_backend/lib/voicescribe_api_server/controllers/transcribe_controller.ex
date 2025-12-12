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

  def upload_chunk(conn, %{"data" => data, "session_id" => _session_id}) do
    # Add rate limiting context for chunk uploads
    user_id = conn.assigns[:current_user]

    case TranscribeSessionManager.add_chunk(user_id, data) do
      :ok ->
        conn
        |> put_resp_header("x-chunk-status", "received")
        |> json(%{status: "ok", message: "Chunk received"})

      {:error, :session_not_found} ->
        Logger.error("Session not found for user #{user_id}")
        conn
        |> put_status(:not_found)
        |> json(%{status: "error", message: "Session not found"})

      {:error, :session_not_recording} ->
        Logger.error("Session not in recording state for user #{user_id}")
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: "Session is not in recording state"})

      {:error, reason} ->
        Logger.error("Failed to add chunk for user #{user_id}: #{inspect(reason)}")
        conn
        |> put_status(:internal_server_error)
        |> json(%{status: "error", message: "Failed to add chunk: #{inspect(reason)}"})
    end
  end

  def finish_session(conn, %{"session_id" => _session_id}) do
    user_id = conn.assigns[:current_user]
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

  def get_status(conn, _params) do
    user_id = conn.assigns[:current_user]
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
        conn
        |> put_status(:ok)
        |> json(response)

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
