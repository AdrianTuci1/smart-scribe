defmodule VoiceScribeAPIServer.AudioChannel do
  use Phoenix.Channel
  require Logger
  alias VoiceScribeAPI.AI.TranscribeStreamer

  @impl true
  def join("audio:" <> _session_id, _payload, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_in("start_stream", %{"user_id" => user_id}, socket) do
    Logger.info("Starting audio stream for user: #{user_id}")

    # Start the Transcribe Streamer
    # We pass self() as caller_pid so the streamer can send results back to this channel process
    case TranscribeStreamer.start_link(user_id: user_id, caller_pid: self()) do
      {:ok, pid} ->
        # Generate session_id for persistence
        session_id = UUID.uuid4()

        socket =
          socket
          |> assign(:streamer_pid, pid)
          |> assign(:session_id, session_id)
          |> assign(:user_id, user_id)

        {:reply, :ok, socket}

      {:error, reason} ->
        Logger.error("Failed to start TranscribeStreamer: #{inspect(reason)}")
        {:reply, {:error, %{reason: "Failed to connect to AWS Transcribe"}}, socket}
    end
  end

  @impl true
  def handle_in("audio_chunk", %{"data" => base64_data}, socket) do
    # Handle base64 encoded data (if client sends text frames)
    case Base.decode64(base64_data) do
      {:ok, binary_data} ->
        forward_audio(socket, binary_data)
        {:noreply, socket}

      :error ->
        Logger.error("Invalid base64 audio data")
        {:noreply, socket}
    end
  end

  # If client sends binary frames directly (Phoenix usually handles this via specific format,
  # but standard Phoenix channels are text-based JSON usually unless configured otherwise.
  # For simplicity, we might stick to base64 in JSON first, or raw binary if supported).
  # Assuming Base64 for now for compatibility with standard Phoenix clients.

  defp forward_audio(socket, binary_data) do
    if pid = socket.assigns[:streamer_pid] do
      TranscribeStreamer.send_audio_chunk(pid, binary_data)
    else
      # If no streamer is active, we can log a warning.
      # Ideally we might buffer or wait, but simpler to just warn for now
      # as the client fix should prevent this.
      Logger.warn("Received audio chunk but no streamer is active")
    end
  end

  @impl true
  def handle_in("stop_stream", _payload, socket) do
    if pid = socket.assigns[:streamer_pid] do
      TranscribeStreamer.stop_stream(pid)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:transcription_complete, _user_id, transcript}, socket) do
    # This is the final full transcript.
    # 1. Process with Bedrock
    # 2. Save to DynamoDB
    # 3. Push to client

    user_id = socket.assigns[:user_id]
    session_id = socket.assigns[:session_id]

    Task.start(fn ->
      Logger.info("Processing complete transcription for session #{session_id}")
      Logger.info("AudioChannel received transcript length: #{String.length(transcript)}")
      Logger.info("AudioChannel received transcript content: '#{transcript}'")

      # 1. Correct
      final_text =
        case VoiceScribeAPI.AI.BedrockClient.correct_text(user_id, transcript) do
          {:ok, corrected} -> corrected
          _ -> transcript
        end

      # 2. Save
      transcript_record = %{
        "userId" => user_id,
        "transcriptId" => session_id,
        "originalText" => transcript,
        "enhancedText" => final_text,
        "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601()
      }

      VoiceScribeAPI.DynamoDBRepo.save_transcript(transcript_record)

      # 3. Push to Client
      VoiceScribeAPIServer.Endpoint.broadcast("audio:#{user_id}", "transcript_content", %{
        content: final_text
      })

      Logger.info("Session #{session_id} completed and saved.")
    end)

    {:noreply, socket}
  end

  # Remove the intermediate handler we added previously

  # Handle partial results if needed (TranscribeStreamer needs update to send them)
  # For now, let's assume we just wait for the end or handle basic completion.

  @impl true
  def terminate(_reason, socket) do
    if pid = socket.assigns[:streamer_pid] do
      TranscribeStreamer.stop_stream(pid)
    end

    :ok
  end
end
