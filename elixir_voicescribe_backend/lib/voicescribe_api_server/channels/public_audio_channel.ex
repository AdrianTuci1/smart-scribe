defmodule VoiceScribeAPIServer.PublicAudioChannel do
  use Phoenix.Channel
  require Logger
  alias VoiceScribeAPI.AI.TranscribeStreamer

  # 150 seconds
  @max_duration_ms 150_000
  # 1 hour
  @rate_limit_scale 3_600_000
  # 20 requests per hour
  @rate_limit_count 20

  @impl true
  def join("public_audio:" <> _session_id, _payload, socket) do
    remote_ip = socket.assigns[:remote_ip] || {127, 0, 0, 1}
    ip_string = :inet.ntoa(remote_ip) |> to_string()

    # Rate Limiting Check
    case Hammer.check_rate(
           "public_transcription:#{ip_string}",
           @rate_limit_scale,
           @rate_limit_count
         ) do
      {:allow, _count} ->
        {:ok, socket}

      {:deny, _limit} ->
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
  def handle_info({:transcription_complete, _user_id, transcript}, socket) do
    # For public route:
    # 1. NO Bedrock correction (save costs) OR simple correction if desired?
    #    Let's stick to raw transcript or minimal correction to keep it cheap/fast for demo.
    #    User requested NO saving to DynamoDB.

    # 2. Push to client
    if String.trim(transcript) != "" do
      VoiceScribeAPIServer.Endpoint.broadcast(
        "public_audio:#{socket.assigns.session_id}",
        "transcript_content",
        %{
          content: transcript
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
