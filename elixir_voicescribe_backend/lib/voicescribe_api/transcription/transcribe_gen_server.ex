defmodule VoiceScribeAPI.Transcription.TranscribeGenServer do
  use GenServer
  require Logger
  alias VoiceScribeAPI.AI.BedrockClient
  alias VoiceScribeAPIServer.Endpoint
  alias UUID
  require URI
  require Jason

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def send_audio(user_id, data) do
    GenServer.call(__MODULE__, {:send_audio, user_id, data})
  end

  def start_session(user_id) do
    GenServer.call(__MODULE__, {:start_session, user_id})
  end

  def stop_session(user_id) do
    GenServer.call(__MODULE__, {:stop_session, user_id})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Table to store user sessions: %{user_id => %{pid: pid, buffer: [], audio_buffer: <<>>}}
    {:ok, %{sessions: %{}}}
  end

  @impl true
  def handle_call({:start_session, user_id}, _from, state) do
    Logger.info("Starting transcription session for user: #{user_id}")

    # Start a new process to handle AWS Transcribe WebSocket connection
    {:ok, pid} = Task.start_link(fn -> aws_transcribe_worker(user_id) end)

    new_sessions = Map.put(state.sessions, user_id, %{pid: pid, audio_buffer: <<>>})
    {:reply, {:ok, pid}, %{state | sessions: new_sessions}}
  end

  @impl true
  def handle_call({:stop_session, user_id}, _from, state) do
    case Map.get(state.sessions, user_id) do
      %{pid: pid} ->
        # Terminate the transcribe worker process
        Process.exit(pid, :normal)
        Logger.info("Stopped transcription session for user: #{user_id}")
      _ ->
        Logger.warning("No session found for user: #{user_id}")
    end

    new_sessions = Map.delete(state.sessions, user_id)
    {:reply, :ok, %{state | sessions: new_sessions}}
  end

  @impl true
  def handle_call({:send_audio, user_id, data}, _from, state) do
    case Map.get(state.sessions, user_id) do
      %{pid: pid} ->
        # Forward audio data to the transcribe worker process
        send(pid, {:audio_data, data})
        {:reply, :ok, state}
      _ ->
        Logger.warning("No session found for user: #{user_id}")
        {:reply, {:error, :no_session}, state}
    end
  end

  @impl true
  def handle_info({:transcription_result, user_id, text}, state) do
    Logger.info("Received transcription for user #{user_id}: #{String.slice(text, 0, 50)}...")

    # Process the text through Bedrock for correction based on user preferences
    Task.start(fn ->
      case BedrockClient.correct_text(user_id, text) do
        {:ok, corrected} ->
          # Send the corrected text back to the client
          Endpoint.broadcast("transcription:#{user_id}", "transcription", %{
            text: corrected,
            original: text
          })

          # Also send the correction event for compatibility
          Endpoint.broadcast("transcription:#{user_id}", "correction", %{
            original: text,
            corrected: corrected
          })
        {:error, reason} ->
          Logger.error("Failed to correct text: #{inspect(reason)}")
          # Send the original text if correction fails
          Endpoint.broadcast("transcription:#{user_id}", "transcription", %{
            text: text,
            original: text
          })
      end
    end)

    {:noreply, state}
  end

  # Worker function that connects to AWS Transcribe WebSocket
  defp aws_transcribe_worker(user_id) do
    # AWS Transcribe WebSocket URL for real-time streaming
    region = System.get_env("AWS_REGION", "eu-central-1")

    # Generate presigned URL for AWS Transcribe
    transcribe_url = "wss://transcribestreaming.#{region}.amazonaws.com:8443"

    # Create a unique session ID
    session_id = UUID.uuid4() |> to_string()

    # Create request parameters
    params = %{
      "language-code" => "en-US",
      "media-encoding" => "pcm",
      "sample-rate" => "16000",
      "session-id" => session_id,
      "vocabulary-filter-name" => "custom_vocabulary",
      "vocabulary-filter-terms" => get_vocabulary_terms(user_id)
    }

    # Convert params to query string
    query_string = URI.encode_query(params)

    # Full WebSocket URL with parameters
    websocket_url = "#{transcribe_url}?#{query_string}"

    # Create request headers with AWS signature
    headers = [
      {"Authorization", "AWS4-HMAC-SHA256 Credential=#{System.get_env("AWS_ACCESS_KEY_ID")}/#{Date.utc_today()}/#{region}/transcribe/aws4_request,SignedHeaders=host;x-amz-date,Signature=#{generate_aws_signature(websocket_url, region)}"},
      {"x-amz-date", DateTime.utc_now() |> DateTime.to_iso8601()},
      {"Origin", "http://localhost:4000"}
    ]

    # Connect to AWS Transcribe WebSocket
    state = %{parent_pid: self()}
    case WebSockex.start_link(websocket_url, __MODULE__.TranscribeClient, state, extra_headers: headers) do
      {:ok, pid} ->
        Logger.info("Connected to AWS Transcribe for user #{user_id}")
        # Start with empty audio buffer
        transcribe_receive_loop(pid, user_id, <<>>)
      {:error, reason} ->
        Logger.error("Failed to connect to AWS Transcribe: #{inspect(reason)}")
        # Fall back to simulation for development
        transcribe_simulation_loop(user_id)
    end
  end

  # Loop to receive messages from AWS Transcribe
  defp transcribe_receive_loop(pid, user_id, audio_buffer) do
    receive do
      {:text, message} ->
        case Jason.decode!(message) do
          %{"TranscriptEvent" => transcript_event} ->
            handle_transcript_event(transcript_event, user_id, audio_buffer)
          _ ->
            Logger.debug("Received unknown message: #{message}")
        end

        # Continue receiving
        transcribe_receive_loop(pid, user_id, audio_buffer)

      {:audio_data, data} ->
        # Buffer audio chunks to optimal size for AWS Transcribe
        # AWS Transcribe works best with audio chunks of around 100ms-200ms
        # For 16kHz PCM audio, this is approximately 3200-6400 bytes
        new_buffer = audio_buffer <> data

        # Check if we have enough audio data to send (e.g., 100ms of audio at 16kHz)
        # 16,000 samples per second * 0.1 seconds * 2 bytes per sample = 3,200 bytes
        if byte_size(new_buffer) >= 3200 do
          # Send the buffered audio to AWS Transcribe
          if pid do
            WebSockex.send_frame(pid, {:binary, new_buffer})
          end

          # Reset buffer after sending
          transcribe_receive_loop(pid, user_id, <<>>)
        else
          # Continue accumulating
          transcribe_receive_loop(pid, user_id, new_buffer)
        end

      {:close, _reason} ->
        Logger.info("AWS Transcribe connection closed for user #{user_id}")
    end
  end

  # Handle transcript events from AWS Transcribe
  defp handle_transcript_event(%{"TranscriptResult" => %{"Transcript" => transcript}}, user_id, _audio_buffer) do
    # Send the transcription result to the main process for Bedrock correction
    send(self(), {:transcription_result, user_id, transcript})
  end

  defp handle_transcript_event(event, user_id, audio_buffer) do
    Logger.debug("Received transcript event: #{inspect(event)}")

    # Continue with current buffer
    transcribe_receive_loop(nil, user_id, audio_buffer)
  end

  # Fallback simulation for development when AWS is not available
  defp transcribe_simulation_loop(user_id) do
    Logger.info("Using simulation mode for transcription")

    receive do
      {:audio_data, _data} ->
        # Simulate processing of audio chunks
        Process.sleep(200)  # Simulate processing time

        # Generate simulated transcription for the chunk
        simulated_text = "simulated transcription chunk"
        send(self(), {:transcription_result, user_id, simulated_text})

        transcribe_simulation_loop(user_id)

      {:close, _reason} ->
        Logger.info("Simulation session closed for user #{user_id}")
    end
  end

  # Generate AWS Signature Version 4
  defp generate_aws_signature(_url, _region) do
    # This is a simplified version - in production you would implement: full AWS SigV4 signing process
    # For now, we'll return a placeholder that allows testing
    "mock_signature_#{System.monotonic_time(:millisecond)}"
  end

  # Get vocabulary terms from user dictionary
  defp get_vocabulary_terms(user_id) do
    case VoiceScribeAPI.DynamoDBRepo.get_config(user_id, "dictionary") do
      {:ok, %{"Item" => item}} ->
        dictionary = ExAws.Dynamo.decode_item(item)
        case dictionary["entries"] do
          nil -> ""
          entries when is_list(entries) ->
            entries
            |> Enum.map(fn entry -> entry["correct_word"] end)
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(",")
        end
      _ -> ""
    end
  end

  # WebSockex client module for AWS Transcribe
  defmodule TranscribeClient do
    use WebSockex

    def handle_frame({:text, msg}, state) do
      # Forward message to parent process
      send(state[:parent_pid], {:text, msg})
      {:ok, state}
    end

    def handle_cast({:send, frame}, state) do
      {:reply, frame, state}
    end

    def handle_disconnect(%{reason: reason}, state) do
      Logger.info("WebSocket disconnected: #{inspect(reason)}")
      {:ok, state}
    end
  end
end
