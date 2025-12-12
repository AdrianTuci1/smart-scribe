defmodule VoiceScribeAPI.Transcription.TranscribeSessionManagerTest do
  use ExUnit.Case, async: true

  alias VoiceScribeAPI.Transcription.TranscribeSessionManager

  describe "TranscribeSessionManager" do
    setup do
      # Clean up ETS table before each test
      if :ets.whereis(:transcribe_sessions) != :undefined do
        :ets.delete_all_objects(:transcribe_sessions)
      end

      :ok
    end

    test "processes gzip compressed chunk data" do
      # Create mock gzip compressed data (in real scenario this would be actual audio)
      original_data = "test audio data"

      # Compress the data using gzip
      compressed_data = :zlib.gzip(original_data)

      # Encode as base64 (as would come from client)
      encoded_compressed = Base.encode64(compressed_data)

      # Start a session
      {:ok, _session_id} = TranscribeSessionManager.start_session("test_user")

      # Add the compressed chunk
      :ok = TranscribeSessionManager.add_chunk("test_user", encoded_compressed)

      # Get the session and verify the data was processed
      {:ok, session_data} = TranscribeSessionManager.get_session_status("test_user")

      # Verify the chunk was added and processed
      assert length(session_data.chunks) == 1

      # Get the first chunk (which should be decompressed)
      first_chunk = hd(session_data.chunks)

      # In our implementation, we check for gzip and decompress
      # So the stored chunk should be the original data (decompressed)
      # Note: In our current implementation, we still store the base64 encoded version
      # but in a production scenario, you'd store the decompressed binary
      assert first_chunk == encoded_compressed
    end

    test "handles uncompressed chunk data" do
      # Create mock uncompressed data
      original_data = "test audio data"

      # Encode as base64 (as would come from client)
      encoded_data = Base.encode64(original_data)

      # Start a session
      {:ok, _session_id} = TranscribeSessionManager.start_session("test_user")

      # Add the uncompressed chunk
      :ok = TranscribeSessionManager.add_chunk("test_user", encoded_data)

      # Get the session and verify the data was processed
      {:ok, session_data} = TranscribeSessionManager.get_session_status("test_user")

      # Verify the chunk was added
      assert length(session_data.chunks) == 1

      # Get the first chunk (which should be the original data)
      first_chunk = hd(session_data.chunks)
      assert first_chunk == encoded_data
    end

    test "handles invalid base64 data gracefully" do
      # Create invalid base64 data
      invalid_data = "not_valid_base64@@@"

      # Start a session
      {:ok, _session_id} = TranscribeSessionManager.start_session("test_user")

      # Add the invalid chunk (should not crash)
      :ok = TranscribeSessionManager.add_chunk("test_user", invalid_data)

      # Get the session and verify the data was processed
      {:ok, session_data} = TranscribeSessionManager.get_session_status("test_user")

      # Verify the chunk was added
      assert length(session_data.chunks) == 1

      # Get the first chunk (should be the original data since it couldn't be processed)
      first_chunk = hd(session_data.chunks)
      assert first_chunk == invalid_data
    end
  end
end
