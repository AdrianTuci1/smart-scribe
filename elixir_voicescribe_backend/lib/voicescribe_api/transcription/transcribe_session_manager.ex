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
        # Check if chunk is gzip compressed and decompress if needed
        processed_chunk_data = process_chunk_data(chunk_data)

        updated_chunks = [processed_chunk_data | session_data.chunks]
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

  defp process_chunk_data(chunk_data) do
    # Check if the chunk data appears to be base64 encoded gzip
    # In a real implementation, you would check for gzip magic bytes (0x1F 0x8B)
    # after base64 decoding

    try do
      # Try to decode as base64 first
      case Base.decode64(chunk_data) do
        {:ok, binary} ->
          # Check if it's gzip compressed (starts with 0x1F, 0x8B)
          case binary do
            <<0x1F, 0x8B, _rest::binary>> ->
              # It's gzip compressed, decompress it
              Logger.debug("Decompressing gzip chunk for user")
              case :zlib.gunzip(binary) do
                {:ok, decompressed} ->
                  # Convert back to base64 for storage
                  Base.encode64(decompressed)
                {:error, _reason} ->
                  # If decompression fails, use original
                  Logger.warning("Failed to decompress gzip chunk, using original")
                  chunk_data
              end
            _ ->
              # Not gzip, use as-is
              Logger.debug("Received uncompressed chunk")
              chunk_data
          end
        _ ->
          # If decoding fails, use as-is
          Logger.debug("Chunk is not base64 encoded, using as-is")
          chunk_data
      end
    rescue
      e ->
        Logger.error("Error processing chunk data: #{inspect(e)}")
        chunk_data
    end
  end

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
      {final_result, original_text} =
        case transcription_result do
          {:ok, transcribed_text} ->
            Logger.info("Transcription successful for session #{session_data.session_id}")

            # Process with Bedrock for enhancement
            case BedrockClient.correct_text(user_id, transcribed_text) do
              {:ok, enhanced_text} ->
                Logger.info("Enhanced transcription for session #{session_data.session_id}")
                {enhanced_text, transcribed_text}
              {:error, reason} ->
                Logger.warning("Failed to enhance transcription: #{inspect(reason)}")
                {transcribed_text, transcribed_text}
            end
          _ ->
            Logger.error("Unexpected transcription result for session #{session_data.session_id}: #{inspect(transcription_result)}")
            {"", ""}
        end

      # Save to DynamoDB
      transcript = %{
        user_id: user_id,
        session_id: session_data.session_id,
        original_text: original_text,
        enhanced_text: final_result,
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      VoiceScribeAPI.DynamoDBRepo.save_transcript(transcript)

      # Update session status
      updated_session = %{session_data | status: :completed}
      :ets.insert(:transcribe_sessions, {user_id, updated_session})

      # Clean up temp file
      File.rm(temp_file)

      Logger.info("Completed transcription for session #{session_data.session_id}")
    rescue
      error ->
        Logger.error("Error in process_transcription: #{inspect(error)}")

        # Update session status to failed
        case :ets.lookup(:transcribe_sessions, user_id) do
          [{^user_id, session_data}] ->
            updated_session = %{session_data | status: :failed}
            :ets.insert(:transcribe_sessions, {user_id, updated_session})
          [] ->
            :ok
        end
    end
  end
end
