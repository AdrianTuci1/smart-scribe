defmodule VoiceScribeAPI.AI.TranscribeStreamer do
  @moduledoc """
  WebSocket client for communicating with AWS Transcribe Streaming.
  """
  use WebSockex
  require Logger
  alias VoiceScribeAPI.AWS.SigV4
  alias VoiceScribeAPI.AWS.EventStream

  def start_link(args) do
    user_id = args[:user_id]

    # Get configuration from env
    region = System.get_env("AWS_REGION", "eu-central-1")
    access_key = System.get_env("AWS_ACCESS_KEY_ID")
    secret_key = System.get_env("AWS_SECRET_ACCESS_KEY")
    session_token = System.get_env("AWS_SESSION_TOKEN")

    if is_nil(access_key) or is_nil(secret_key) do
      {:error, :missing_credentials}
    else
      # Generate Signed URL
      url = SigV4.presigned_url(region, access_key, secret_key, session_token)

      Logger.info("Connecting to AWS Transcribe Streaming...")

      WebSockex.start_link(url, __MODULE__, %{
        user_id: user_id,
        transcript: "",
        # The session manager process to notify
        caller_pid: args[:caller_pid]
      })
    end
  end

  def send_audio_chunk(pid, audio_data) do
    WebSockex.cast(pid, {:send_audio, audio_data})
  end

  def stop_stream(pid) do
    WebSockex.cast(pid, :stop_stream)
  end

  # Callbacks

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Connected to AWS Transcribe Streaming")
    {:ok, state}
  end

  @impl true
  def handle_cast({:send_audio, audio_data}, state) do
    # Encode audio data as AudioEvent
    binary_frame = EventStream.encode_audio_event(audio_data)
    {:reply, {:binary, binary_frame}, state}
  end

  @impl true
  def handle_cast(:stop_stream, state) do
    # Send empty frame to signal end of stream (optional/good practice usually involves sending explicit EOS or just closing)
    # But for now we just wait for final results or close?
    # AWS expects an empty audio chunk as a signal for end of stream usually
    empty_frame = EventStream.encode_audio_event(<<>>)
    {:reply, {:binary, empty_frame}, state}
  end

  @impl true
  def handle_frame({:binary, frame}, state) do
    case EventStream.decode_message(frame) do
      {:ok, %{"Transcript" => %{"Results" => results}}} ->
        # Process partial/final results
        # Accumulate final results into state.transcript

        new_text = extract_text(results)
        updated_transcript = state.transcript <> new_text

        # If the message indicates this is the final event, we could notify the caller
        # But usually we just accumulate until we decide to close

        {:ok, %{state | transcript: updated_transcript}}

      {:error, reason} ->
        Logger.error("Error decoding frame: #{inspect(reason)}")
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  defp extract_text(results) do
    # Extract text only from non-partial (final) results to avoid duplication
    Enum.reduce(results, "", fn result, acc ->
      if Map.get(result, "IsPartial", false) == false do
        alternatives = Map.get(result, "Alternatives", [])
        text = List.first(alternatives) |> Map.get("Transcript", "")
        acc <> text <> " "
      else
        acc
      end
    end)
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    Logger.info("Disconnected from AWS Transcribe: #{inspect(reason)}")

    # Notify caller with the final transcript
    if state.caller_pid do
      send(state.caller_pid, {:transcription_complete, state.user_id, state.transcript})
    end

    {:ok, state}
  end
end
