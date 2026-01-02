defmodule VoiceScribeAPIServer.TranscriptsController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  def list(conn, params) do
    user_id = conn.assigns.current_user

    # Get pagination parameters
    limit = Map.get(params, "limit", "20") |> String.to_integer()
    start_key = Map.get(params, "start_key")

    case DynamoDBRepo.list_transcripts(user_id, limit: limit, start_key: start_key) do
      {:ok, result} ->
        items = (result["Items"] || []) |> Enum.map(&decode_item/1)
        last_evaluated_key = Map.get(result, "LastEvaluatedKey")

        response = %{
          data: items
        }

        # Add pagination info if available
        response =
          if last_evaluated_key do
            Map.put(response, "pagination", %{
              start_key: last_evaluated_key,
              has_more: true
            })
          else
            Map.put(response, "pagination", %{
              has_more: false
            })
          end

        json(conn, response)

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

  def create(conn, params) do
    transcript_id = Map.get(params, "id")
    user_id = conn.assigns.current_user
    content = Map.get(params, "content", "")

    # 1. Validation: Check for empty content
    if String.trim(content) == "" do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Transcript content cannot be empty"})
    else
      # 1.5. Idempotency Check
      case DynamoDBRepo.get_transcript(user_id, transcript_id) do
        {:ok, result} when result != %{} ->
          # Already exists! Return success but DO NOT increment usage.
          Logger.info(
            "Idempotency: Transcript #{transcript_id} already exists for user #{user_id}. Skipping creation and usage update."
          )

          json(conn, %{status: "ok", transcriptId: transcript_id})

        _ ->
          # 2. Check Subscription and Usage
          can_save? =
            case DynamoDBRepo.get_subscription_config(user_id) do
              %{"plan" => "pro"} ->
                true

              _ ->
                # Free tier (or unknown) - Check usage
                usage = DynamoDBRepo.get_usage(user_id)
                # DynamoDB may store wordCount as string, so convert to integer
                current_count =
                  case Map.get(usage, "wordCount", 0) do
                    count when is_integer(count) -> count
                    count when is_binary(count) -> String.to_integer(count)
                    _ -> 0
                  end

                new_words = count_words(content)

                # Limit: 2000 words
                # User modification: Check if we are ALREADY at/over the limit.
                # If we are at 1999, we allow the next one no matter how big.
                if current_count >= 2000 do
                  {:error, :limit_exceeded}
                else
                  true
                end
            end

          case can_save? do
            {:error, :limit_exceeded} ->
              conn
              # 402 Payment Required
              |> put_status(:payment_required)
              |> json(%{error: "Free tier limit exceeded. Please upgrade to Pro."})

            true ->
              transcript_data =
                Map.merge(params, %{
                  "transcriptId" => transcript_id,
                  "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
                  "isFlagged" => false
                })

              case DynamoDBRepo.create_transcript(user_id, transcript_id, transcript_data) do
                {:ok, _} ->
                  # 3. Update Usage (Increment logic handles monthly reset)
                  DynamoDBRepo.update_usage(user_id, count_words(content))
                  json(conn, %{status: "ok", transcriptId: transcript_id})

                {:error, reason} ->
                  conn
                  |> put_status(:bad_request)
                  |> json(%{error: inspect(reason)})
              end
          end
      end
    end
  end

  defp count_words(text) do
    text
    |> String.split(~r/\s+/, trim: true)
    |> length()
  end

  def update(conn, %{"id" => transcript_id} = params) do
    user_id = conn.assigns.current_user

    # Get existing transcript first
    case DynamoDBRepo.get_transcript(user_id, transcript_id) do
      {:ok, result} when result != %{} ->
        existing = decode_item(result["Item"])

        # Merge updates with existing data
        updated_data =
          Map.merge(existing, params)
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
      {:ok, _} ->
        json(conn, %{status: "ok"})

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

          _audio_url ->
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
  defp decode_item(item), do: DynamoDBRepo.decode_item(item)

  def audio(conn, %{"id" => transcript_id}) do
    audio_url(conn, %{"id" => transcript_id})
  end
end
