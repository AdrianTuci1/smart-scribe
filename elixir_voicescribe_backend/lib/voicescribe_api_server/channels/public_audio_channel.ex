defmodule VoiceScribeAPIServer.PublicAudioChannel do
  use Phoenix.Channel
  require Logger
  alias VoiceScribeAPI.AI.TranscribeStreamer
  alias VoiceScribeAPI.AI.BedrockClient

  # 150 seconds
  @max_duration_ms 150_000
  # 1 hour
  @rate_limit_scale 3_600_000
  # 20 requests per hour
  @rate_limit_count 20

  @impl true
  def join("public_audio:" <> session_id, _payload, socket) do
    Logger.info("PublicAudioChannel: Attempting to join public_audio:#{session_id}")
    remote_ip = socket.assigns[:remote_ip] || {127, 0, 0, 1}
    ip_string = :inet.ntoa(remote_ip) |> to_string()
    Logger.info("PublicAudioChannel: Remote IP: #{ip_string}")

    # Rate Limiting Check
    case Hammer.check_rate(
           "public_transcription:#{ip_string}",
           @rate_limit_scale,
           @rate_limit_count
         ) do
      {:allow, _count} ->
        Logger.info("PublicAudioChannel: Rate limit check passed for #{ip_string}")
        socket = assign(socket, :topic_id, session_id)
        {:ok, socket}

      {:deny, _limit} ->
        Logger.warning("PublicAudioChannel: Rate limit exceeded for #{ip_string}")
        {:error, %{reason: "rate_limit_exceeded"}}
    end
  end

  @impl true
  def handle_in("start_stream", _payload, socket) do
    # Public session always generates a new transient ID
    session_id = UUID.uuid4()
    Logger.info("Starting public stream for session: #{session_id}")

    # Start TranscribeStreamer
    # Use session_id as user_id for the streamer to reuse logic
    case TranscribeStreamer.start_link(user_id: session_id, caller_pid: self()) do
      {:ok, pid} ->
        socket =
          socket
          |> assign(:streamer_pid, pid)
          |> assign(:session_id, session_id)

        # Enforce max duration
        Process.send_after(self(), :limit_duration, @max_duration_ms)

        {:reply, :ok, socket}

      {:error, reason} ->
        Logger.error("Failed to start public TranscribeStreamer: #{inspect(reason)}")
        {:reply, {:error, %{reason: "upstream_error"}}, socket}
    end
  end

  @impl true
  def handle_in("audio_chunk", %{"data" => base64_data}, socket) do
    case Base.decode64(base64_data) do
      {:ok, binary_data} ->
        if pid = socket.assigns[:streamer_pid] do
          TranscribeStreamer.send_audio_chunk(pid, binary_data)
        end

        {:noreply, socket}

      :error ->
        {:noreply, socket}
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
  def handle_info(:limit_duration, socket) do
    Logger.info("Public session #{socket.assigns[:session_id]} exceeded duration limit.")

    if pid = socket.assigns[:streamer_pid] do
      TranscribeStreamer.stop_stream(pid)
    end

    push(socket, "error", %{reason: "duration_limit_exceeded"})
    {:stop, :normal, socket}
  end

  @impl true
  @impl true
  def handle_info({:transcription_complete, _user_id, transcript, _duration}, socket) do
    # 1. Process with Bedrock
    # Use the session_id as the user_id context for Bedrock (though it likely won't have personalized dictionaries)
    enhanced_text =
      if String.trim(transcript) != "" do
        case BedrockClient.correct_text(socket.assigns.session_id, transcript) do
          {:ok, text} -> text
          {:error, _} -> transcript
        end
      else
        transcript
      end

    # 2. Push to client
    if String.trim(enhanced_text) != "" do
      VoiceScribeAPIServer.Endpoint.broadcast(
        "public_audio:#{socket.assigns.topic_id}",
        "transcript_content",
        %{
          content: enhanced_text
        }
      )
    end

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if pid = socket.assigns[:streamer_pid] do
      TranscribeStreamer.stop_stream(pid)
    end

    :ok
  end
end
