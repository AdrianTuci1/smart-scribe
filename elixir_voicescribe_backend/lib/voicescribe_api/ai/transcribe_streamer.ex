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
    access_key = System.get_env("AWS_ACCESS_KEY_ID") |> String.trim()
    secret_key = System.get_env("AWS_SECRET_ACCESS_KEY") |> String.trim()

    session_token =
      case System.get_env("AWS_SESSION_TOKEN") do
        nil -> nil
        token -> String.trim(token)
      end

    if is_nil(access_key) or is_nil(secret_key) do
      {:error, :missing_credentials}
    else
      # Generate Signed URL
      url = SigV4.presigned_url(region, access_key, secret_key, session_token)

      Logger.info("Connecting to AWS Transcribe Streaming...")

      WebSockex.start_link(url, __MODULE__, %{
        user_id: user_id,
        transcript: "",
        last_partial: "",
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
        {updated_transcript, new_last_partial} =
          process_results(results, state.transcript, state.last_partial)

        {:ok, %{state | transcript: updated_transcript, last_partial: new_last_partial}}

      {:error, reason} ->
        Logger.error("Error decoding frame: #{inspect(reason)}")
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  defp process_results(results, current_transcript, current_last_partial) do
    Enum.reduce(results, {current_transcript, current_last_partial}, fn result,
                                                                        {acc_transcript,
                                                                         _acc_partial} ->
      is_partial = Map.get(result, "IsPartial", false)
      alternatives = Map.get(result, "Alternatives", [])

      text =
        case List.first(alternatives) do
          nil -> ""
          alt -> Map.get(alt, "Transcript", "")
        end

      if is_partial == false do
        if text != "", do: Logger.info("Got final transcript chunk: #{text}")
        {acc_transcript <> text <> " ", ""}
      else
        {acc_transcript, text}
      end
    end)
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    Logger.info("Disconnected from AWS Transcribe: #{inspect(reason)}")

    final_text =
      if String.trim(state.transcript) == "" and String.trim(state.last_partial) != "" do
        Logger.info("Using last partial result as final transcript: #{state.last_partial}")
        state.last_partial
      else
        state.transcript
      end

    # Notify caller with the final transcript
    if state.caller_pid do
      send(state.caller_pid, {:transcription_complete, state.user_id, final_text})
    end

    {:ok, state}
  end
end
