defmodule VoiceScribeAPIServer.TranscriptsController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  def list(conn, _params) do
    user_id = conn.assigns.current_user
    case DynamoDBRepo.list_transcripts(user_id) do
      {:ok, result} ->
        items = (result["Items"] || []) |> Enum.map(&decode_item/1)
        json(conn, %{data: items})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  def show(conn, %{"id" => transcript_id}) do
    user_id = conn.assigns.current_user
    case DynamoDBRepo.get_transcript(user_id, transcript_id) do
      {:ok, result} when result != %{} ->
        item = decode_item(result["Item"])
        json(conn, item)
      {:ok, _} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Transcript not found"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  def create(conn, %{"transcriptId" => transcript_id} = params) do
    user_id = conn.assigns.current_user
    transcript_data = Map.merge(params, %{
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "isFlagged" => false
    })

    case DynamoDBRepo.create_transcript(user_id, transcript_id, transcript_data) do
      {:ok, _} -> json(conn, %{status: "ok", transcriptId: transcript_id})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  def update(conn, %{"id" => transcript_id} = params) do
    user_id = conn.assigns.current_user

    # Get existing transcript first
    case DynamoDBRepo.get_transcript(user_id, transcript_id) do
      {:ok, result} when result != %{} ->
        existing = decode_item(result["Item"])

        # Merge updates with existing data
        updated_data = Map.merge(existing, params)
        |> Map.drop(["id"])

        case DynamoDBRepo.update_transcript(user_id, transcript_id, updated_data) do
          {:ok, _} ->
            # Return updated transcript
            json(conn, Map.put(updated_data, "transcriptId", transcript_id))
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: inspect(reason)})
        end
      {:ok, _} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Transcript not found"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  def delete(conn, %{"id" => transcript_id}) do
    user_id = conn.assigns.current_user
    case DynamoDBRepo.delete_transcript(user_id, transcript_id) do
       {:ok, _} -> json(conn, %{status: "ok"})
       {:error, reason} ->
         conn
         |> put_status(:bad_request)
         |> json(%{error: inspect(reason)})
    end
  end

  def retry(conn, %{"id" => transcript_id}) do
    user_id = conn.assigns.current_user

    # Get existing transcript
    case DynamoDBRepo.get_transcript(user_id, transcript_id) do
      {:ok, result} when result != %{} ->
        existing = decode_item(result["Item"])

        # Check if we have audio URL to retry transcription
        case Map.get(existing, "audioUrl") do
          nil ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "No audio available for retry"})

          audio_url ->
            # TODO: Trigger re-transcription with the audio file
            # For now, return the existing transcript
            # In production, this would queue a new transcription job
            json(conn, Map.put(existing, "transcriptId", transcript_id))
        end
      {:ok, _} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Transcript not found"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  def audio_url(conn, %{"id" => transcript_id}) do
    user_id = conn.assigns.current_user

    case DynamoDBRepo.get_transcript(user_id, transcript_id) do
      {:ok, result} when result != %{} ->
        existing = decode_item(result["Item"])

        case Map.get(existing, "audioUrl") do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "No audio available for this transcript"})

          audio_url ->
            # Return the audio URL (could be a pre-signed S3 URL)
            json(conn, %{url: audio_url})
        end
      {:ok, _} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Transcript not found"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  defp decode_item(nil), do: %{}
  defp decode_item(item), do: ExAws.Dynamo.decode_item(item)
end
