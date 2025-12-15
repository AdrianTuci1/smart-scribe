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
        socket = assign(socket, :streamer_pid, pid)
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
    # Push the result back to the client
    push(socket, "transcription_complete", %{transcript: transcript})
    {:noreply, socket}
  end

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
