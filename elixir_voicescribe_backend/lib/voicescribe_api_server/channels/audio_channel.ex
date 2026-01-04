defmodule VoiceScribeAPIServer.AudioChannel do
  use Phoenix.Channel
  require Logger
  alias VoiceScribeAPI.AI.TranscribeStreamer
  alias VoiceScribeAPI.DynamoDBRepo

  @impl true
  def join("audio:" <> _session_id, _payload, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_in("start_stream", %{"user_id" => user_id}, socket) do
    Logger.info("Starting audio stream for user: #{user_id}")

    # Check Usage Limits
    subscription_config = DynamoDBRepo.get_subscription_config(user_id)
    Logger.info("Subscription config for user #{user_id}: #{inspect(subscription_config)}")

    can_stream? =
      case subscription_config do
        %{"plan" => "pro"} ->
          Logger.info("User #{user_id} has pro plan")
          true

        _ ->
          usage = DynamoDBRepo.get_usage(user_id)
          # DynamoDB may store wordCount as string, so convert to integer
          current_count =
            case Map.get(usage, "wordCount", 0) do
              count when is_integer(count) -> count
              count when is_binary(count) -> String.to_integer(count)
              _ -> 0
            end

          Logger.info("User #{user_id} usage: #{inspect(usage)}, current_count: #{current_count}")
          # Free tier limit is 2000 words - user can stream only if under the limit
          result = current_count < 2000
          Logger.info("Can stream? #{result} (#{current_count} < 2000)")
          result
      end

    if can_stream? do
      # Start the Transcribe Streamer
      case TranscribeStreamer.start_link(user_id: user_id, caller_pid: self()) do
        {:ok, pid} ->
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
    else
      Logger.warn("User #{user_id} exceeded free tier limit")
      {:reply, {:error, %{reason: "limit_exceeded"}}, socket}
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
  def handle_info({:transcription_complete, user_id, transcript}, socket) do
    # Fallback to 0 duration for legacy calls
    handle_info({:transcription_complete, user_id, transcript, 0}, socket)
  end

  @impl true
  def handle_info({:transcription_complete, _user_id, transcript, duration}, socket) do
    # This is the final full transcript.
    # 1. Process with Bedrock
    # 2. Save to DynamoDB
    # 3. Push to client

    user_id = socket.assigns[:user_id]
    session_id = socket.assigns[:session_id]

    Task.start(fn ->
      try do
        if String.trim(transcript) != "" do
          Logger.info("Processing complete transcription for session #{session_id}")
          Logger.info("AudioChannel received transcript length: #{String.length(transcript)}")

          # 1. Correct
          final_text =
            case VoiceScribeAPI.AI.BedrockClient.correct_text(user_id, transcript) do
              {:ok, corrected} ->
                Logger.info(
                  "AudioChannel: Correction successful. Original: #{String.length(transcript)} chars, Corrected: #{String.length(corrected)} chars."
                )

                corrected

              {:error, reason} ->
                Logger.error("AudioChannel: Correction failed: #{inspect(reason)}")
                transcript

              _ ->
                Logger.warn("AudioChannel: Correction returned unexpected format.")
                transcript
            end

          # Check again if result isn't empty after correction (though unlikely to become empty if input wasn't)
          if String.trim(final_text) != "" do
            # 2. Save
            transcript_record = %{
              "userId" => user_id,
              "transcriptId" => session_id,
              "originalText" => transcript,
              "enhancedText" => final_text,
              "durationSeconds" => duration,
              "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601()
            }

            try do
              VoiceScribeAPI.DynamoDBRepo.save_transcript(transcript_record)
            rescue
              e -> Logger.error("Failed to save transcript: #{inspect(e)}")
            end

            # 2.1 Update Usage (Count words of final text)
            word_count =
              final_text
              |> String.split(~r/\s+/, trim: true)
              |> length()

            try do
              DynamoDBRepo.update_usage(user_id, word_count)
            rescue
              e -> Logger.error("Failed to update usage: #{inspect(e)}")
            end

            # 3. Push to Client
            Logger.info("Broadcasting to client: audio:#{user_id}")

            VoiceScribeAPIServer.Endpoint.broadcast("audio:#{user_id}", "transcript_content", %{
              content: final_text
            })

            Logger.info("Session #{session_id} completed. Saved #{word_count} words.")
          else
            Logger.info("Session #{session_id} yielded empty text after correction. Ignoring.")
          end
        else
          Logger.info("Session #{session_id} received empty transcript. Ignoring.")
        end
      rescue
        e ->
          Logger.error("CRITICAL ERROR in AudioChannel Task: #{inspect(e)}")
          Logger.error(Exception.format(:error, e, __STACKTRACE__))

          # Emergency fallback
          VoiceScribeAPIServer.Endpoint.broadcast("audio:#{user_id}", "transcript_content", %{
            content: transcript
          })
      end
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
