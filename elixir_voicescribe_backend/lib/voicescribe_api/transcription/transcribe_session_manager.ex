defmodule VoiceScribeAPI.Transcription.TranscribeSessionManager do
  @moduledoc """
  Manager for transcription sessions.
  Uses TranscribeStreamer for real-time streaming to AWS Transcribe.
  """

  use GenServer
  require Logger

  alias VoiceScribeAPI.AI.BedrockClient
  alias VoiceScribeAPI.AI.TranscribeStreamer

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_session(user_id) do
    GenServer.call(__MODULE__, {:start_session, user_id})
  end

  def add_chunk(user_id, chunk_data) do
    GenServer.call(__MODULE__, {:add_chunk, user_id, chunk_data})
  end

  def finish_session(user_id) do
    GenServer.call(__MODULE__, {:finish_session, user_id})
  end

  def get_session_status(user_id) do
    GenServer.call(__MODULE__, {:get_session, user_id})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for storing session data
    :ets.new(:transcribe_sessions, [:set, :public, :named_table])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:start_session, user_id}, _from, state) do
    session_id = generate_session_id()

    # Start the WebSocket streamer
    # We pass the user_id and this PID to notify when done
    {:ok, streamer_pid} = TranscribeStreamer.start_link(user_id: user_id, caller_pid: self())

    session_data = %{
      user_id: user_id,
      session_id: session_id,
      streamer_pid: streamer_pid,
      status: :recording,
      final_result: nil,
      created_at: DateTime.utc_now()
    }

    # Store in ETS table
    :ets.insert(:transcribe_sessions, {user_id, session_data})

    Logger.info("Started streaming session #{session_id} for user #{user_id}")
    {:reply, {:ok, session_id}, state}
  end

  @impl true
  def handle_call({:add_chunk, user_id, chunk_data}, _from, state) do
    case :ets.lookup(:transcribe_sessions, user_id) do
      [{^user_id, session_data}] when session_data.status == :recording ->
        # Decode base64 to binary
        binary_chunk = process_chunk_data(chunk_data)

        # Forward to streamer
        TranscribeStreamer.send_audio_chunk(session_data.streamer_pid, binary_chunk)

        {:reply, :ok, state}

      [{^user_id, _session_data}] ->
        {:reply, {:error, :session_not_recording}, state}

      [] ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  @impl true
  def handle_call({:finish_session, user_id}, _from, state) do
    case :ets.lookup(:transcribe_sessions, user_id) do
      [{^user_id, session_data}] when session_data.status == :recording ->
        # Updated status
        updated_session = %{session_data | status: :processing}
        :ets.insert(:transcribe_sessions, {user_id, updated_session})

        # Stop the stream (this will cause the streamer to close and send back the result)
        TranscribeStreamer.stop_stream(session_data.streamer_pid)

        # We reply with "processing" because we are waiting for the streamer to finish
        {:reply, {:ok, :processing}, state}

      [{^user_id, _session_data}] ->
        {:reply, {:error, :session_not_recording}, state}

      [] ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_session, user_id}, _from, state) do
    case :ets.lookup(:transcribe_sessions, user_id) do
      [{^user_id, session_data}] ->
        # Return a view model
        result_data = %{
          session_id: session_data.session_id,
          status: session_data.status,
          result: session_data.final_result,
          created_at: session_data.created_at,
          # Could add this
          completed_at: nil,
          error: nil
        }

        {:reply, {:ok, result_data}, state}

      [] ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  # Handle message from Streamer when disconnected/finished
  @impl true
  def handle_info({:transcription_complete, user_id, transcript_text}, state) do
    Logger.info("Received transcription complete via Streamer for user #{user_id}")

    with [{^user_id, session_data}] <- :ets.lookup(:transcribe_sessions, user_id) do
      # 1. Process with Bedrock
      final_result = process_bedrock(user_id, transcript_text, session_data.session_id)

      # 2. Save to DynamoDB
      transcript_record = %{
        user_id: user_id,
        session_id: session_data.session_id,
        original_text: transcript_text,
        enhanced_text: final_result,
        created_at: session_data.created_at,
        updated_at: DateTime.utc_now()
      }

      VoiceScribeAPI.DynamoDBRepo.save_transcript(transcript_record)

      # 3. Update Session Status in ETS
      updated_session = %{session_data | status: :completed, final_result: final_result}
      :ets.insert(:transcribe_sessions, {user_id, updated_session})

      Logger.info("Session #{session_data.session_id} fully processed.")
    else
      _ -> Logger.warning("Session not found for user #{user_id} during completion callback.")
    end

    {:noreply, state}
  end

  # Wait! I can't leave it broken.
  # I will update `TranscribeStreamer` FIRST in the next tool call, then this one.

  # Or better: I will write `TranscribeStreamer` again with the fix, THEN this file.
  # But I already wrote TranscribeStreamer in step 78.

  # OK, I will rewrite `TranscribeStreamer` to include `user_id` in the message.

  defp process_chunk_data(chunk_data) do
    # Same as before, decode base64
    case Base.decode64(chunk_data) do
      {:ok, binary} -> binary
      _ -> <<>>
    end
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp process_bedrock(user_id, text, session_id) do
    Logger.info("Processing Bedrock for session #{session_id}")

    case BedrockClient.correct_text(user_id, text) do
      {:ok, enhanced_text} ->
        enhanced_text

      {:error, _} ->
        text
    end
  end
end
