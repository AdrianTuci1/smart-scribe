defmodule VoiceScribeAPI.AI.TranscribeClient do
  @moduledoc """
  Client for AWS Transcribe service.
  """

  require Logger
  alias ExAws.S3

  @doc """
  Transcribes an audio file using AWS Transcribe.

  ## Parameters
  - file_path: Path to the audio file to transcribe

  ## Returns
  - {:ok, transcribed_text} on success
  - {:error, reason} on failure
  """
  def transcribe_file(file_path) do
    bucket = Application.get_env(:voicescribe_api, :s3_bucket)

    if is_nil(bucket) do
      Logger.error("AWS_S3_BUCKET not configured")
      {:error, :missing_bucket_config}
    else
      filename = Path.basename(file_path)
      # Use a unique prefix to avoid collisions
      s3_key = "uploads/#{UUID.uuid4()}/#{filename}"

      Logger.info("Uploading #{file_path} to s3://#{bucket}/#{s3_key}")

      with {:ok, file_content} <- File.read(file_path),
           {:ok, _} <- S3.put_object(bucket, s3_key, file_content) |> ExAws.request(),
           s3_uri = "s3://#{bucket}/#{s3_key}",
           job_name = "voicescribe-#{UUID.uuid4()}",
           {:ok, _} <- start_transcription_job(s3_uri, job_name),
           {:ok, transcript_uri} <- poll_job_status(job_name) do
        get_transcript_content(transcript_uri)
      else
        error ->
          Logger.error("Transcription failed: #{inspect(error)}")
          {:error, error}
      end
    end
  end

  def start_transcription_job(s3_uri, job_name) do
    Logger.info("Starting transcription job: #{job_name} for #{s3_uri}")

    op = %ExAws.Operation.JSON{
      http_method: :post,
      headers: [
        {"content-type", "application/x-amz-json-1.1"},
        {"x-amz-target", "Transcribe.StartTranscriptionJob"}
      ],
      path: "/",
      data: %{
        TranscriptionJobName: job_name,
        # Defaulting to Romanian as per context
        LanguageCode: "ro-RO",
        Media: %{MediaFileUri: s3_uri},
        MediaFormat: "wav"
      },
      service: :transcribe
    }

    ExAws.request(op, config_overrides())
  end

  def poll_job_status(job_name, attempts \\ 0) do
    # Poll every 2 seconds, max 60 attempts (2 minutes)
    if attempts >= 60 do
      {:error, :timeout}
    else
      Process.sleep(2000)

      case get_transcription_job(job_name) do
        {:ok,
         %{
           "TranscriptionJob" => %{
             "TranscriptionJobStatus" => "COMPLETED",
             "Transcript" => %{"TranscriptFileUri" => uri}
           }
         }} ->
          Logger.info("Transcription job #{job_name} completed")
          {:ok, uri}

        {:ok,
         %{
           "TranscriptionJob" => %{
             "TranscriptionJobStatus" => "FAILED",
             "FailureReason" => reason
           }
         }} ->
          Logger.error("Transcription job #{job_name} failed: #{reason}")
          {:error, reason}

        {:ok, _} ->
          # Still in progress
          poll_job_status(job_name, attempts + 1)

        error ->
          Logger.error("Error checking job status: #{inspect(error)}")
          poll_job_status(job_name, attempts + 1)
      end
    end
  end

  def get_transcription_job(job_name) do
    op = %ExAws.Operation.JSON{
      http_method: :post,
      headers: [
        {"content-type", "application/x-amz-json-1.1"},
        {"x-amz-target", "Transcribe.GetTranscriptionJob"}
      ],
      path: "/",
      data: %{
        TranscriptionJobName: job_name
      },
      service: :transcribe
    }

    case ExAws.request(op, config_overrides()) do
      {:ok, %{body: body}} -> {:ok, Jason.decode!(body)}
      error -> error
    end
  end

  def get_transcript_content(transcript_uri) do
    Logger.info("Downloading transcript from #{transcript_uri}")

    # The transcript URI is a presigned URL. We can use HTTPoison to fetch it.
    case HTTPoison.get(transcript_uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        try do
          json = Jason.decode!(body)
          # Extract the full transcript text
          # Structure: results -> transcripts -> [0] -> transcript
          text =
            json
            |> Map.get("results", %{})
            |> Map.get("transcripts", [])
            |> List.first(%{})
            |> Map.get("transcript", "")

          {:ok, text}
        rescue
          e ->
            Logger.error("Failed to parse transcript JSON: #{inspect(e)}")
            {:error, :parsing_error}
        end

      {:ok, response} ->
        Logger.error("Failed to download transcript. Status: #{response.status_code}")
        {:error, :download_failed}

      {:error, reason} ->
        Logger.error("Failed to download transcript: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp config_overrides do
    %{
      host: "transcribe.#{region()}.amazonaws.com",
      scheme: "https",
      region: region(),
      service: "transcribe",
      port: 443
    }
  end

  defp region do
    System.get_env("AWS_REGION", "eu-central-1")
  end
end
