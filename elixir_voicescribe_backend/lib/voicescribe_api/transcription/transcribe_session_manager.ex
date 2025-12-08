defmodule VoiceScribeAPI.Transcription.TranscribeSessionManager do
  @moduledoc """
  Manager for transcription sessions that handles audio chunks and processes them
  through AWS Transcribe in batch mode.
  """

  use GenServer
  require Logger

  alias VoiceScribeAPI.AI.BedrockClient
  alias VoiceScribeAPI.AI.TranscribeClient

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

    session_data = %{
      user_id: user_id,
      session_id: session_id,
      chunks: [],
      status: :recording,
      created_at: DateTime.utc_now()
    }

    # Store in ETS table
    :ets.insert(:transcribe_sessions, {user_id, session_data})

    Logger.info("Started transcription session #{session_id} for user #{user_id}")
    {:reply, {:ok, session_id}, state}
  end

  @impl true
  def handle_call({:add_chunk, user_id, chunk_data}, _from, state) do
    case :ets.lookup(:transcribe_sessions, user_id) do
      [{^user_id, session_data}] when session_data.status == :recording ->
        updated_chunks = [chunk_data | session_data.chunks]
        updated_session = %{session_data | chunks: updated_chunks}

        # Update in ETS table
        :ets.insert(:transcribe_sessions, {user_id, updated_session})

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
        # Mark session as processing
        updated_session = %{session_data | status: :processing}
        :ets.insert(:transcribe_sessions, {user_id, updated_session})

        # Start async transcription process
        Task.start(fn -> process_transcription(user_id, session_data) end)

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
        {:reply, {:ok, session_data}, state}

      [] ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  # Private Functions

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp process_transcription(user_id, session_data) do
    try do
      # Combine chunks into a single binary
      audio_data = session_data.chunks |> Enum.reverse() |> IO.iodata_to_binary()

      # Create temporary file
      temp_file = "/tmp/#{session_data.session_id}.wav"
      File.write!(temp_file, audio_data)

      # Send to AWS Transcribe
      transcription_result = TranscribeClient.transcribe_file(temp_file)

      # Process with Bedrock if transcription succeeded
      final_result =
        case transcription_result do
          {:ok, transcribed_text} ->
            Logger.info("Transcription completed for session #{session_data.session_id}")
            BedrockClient.process_text(transcribed_text)

          {:error, reason} ->
            Logger.error("Transcription failed for session #{session_data.session_id}: #{inspect(reason)}")
            {:error, reason}
        end

      # Update session with final result
      updated_session = %{session_data |
        status: :completed,
        result: final_result,
        completed_at: DateTime.utc_now()
      }

      :ets.insert(:transcribe_sessions, {user_id, updated_session})

      # Clean up temp file
      File.rm(temp_file)

    rescue
      error ->
        Logger.error("Error processing transcription for session #{session_data.session_id}: #{inspect(error)}")

        # Update session with error
        updated_session = %{session_data |
          status: :failed,
          error: inspect(error),
          completed_at: DateTime.utc_now()
        }

        :ets.insert(:transcribe_sessions, {user_id, updated_session})
    end
  end
end
