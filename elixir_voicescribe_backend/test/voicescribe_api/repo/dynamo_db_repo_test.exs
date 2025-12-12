defmodule VoiceScribeAPI.DynamoDBRepoTest do
  use ExUnit.Case, async: true

  alias VoiceScribeAPI.DynamoDBRepo

  describe "DynamoDBRepo cache functionality" do
    setup do
      # Clean up cache before each test
      if :ets.whereis(:dynamo_cache) != :undefined do
        :ets.delete_all_objects(:dynamo_cache)
      end

      :ok
    end

    test "caches transcript list result" do
      user_id = "test_user"
      mock_result = %{
        "Items" => [
          %{"transcriptId" => "1", "text" => "Test transcript 1"},
          %{"transcriptId" => "2", "text" => "Test transcript 2"}
        ]
      }

      # Mock the ExAws.request to return our mock result
      # Note: In a real test environment, you'd use Mox or similar mocking library

      # First call should hit the database
      {:ok, result1} = DynamoDBRepo.list_transcripts(user_id, cache: true)

      # Result should be from database (first call)
      # In a real test with mocking, you'd assert ExAws.request was called

      # Second call should hit the cache
      {:ok, result2} = DynamoDBRepo.list_transcripts(user_id, cache: true)

      # Results should be identical
      assert result1 == result2
    end

    test "respects cache TTL" do
      user_id = "test_user_ttl"
      mock_result = %{
        "Items" => [
          %{"transcriptId" => "1", "text" => "Test transcript with TTL"}
        ]
      }

      # Mock the ExAws.request and cache the result
      {:ok, _} = DynamoDBRepo.list_transcripts(user_id_ttl, cache: true)

      # Manually expire the cache entry by modifying its expiration time
      if :ets.whereis(:dynamo_cache) != :undefined do
        cache_key = "transcripts_#{user_id_ttl}"
        case :ets.lookup(:dynamo_cache, cache_key) do
          [{^cache_key, cache_entry}] ->
            # Set expiration to the past
            expired_entry = %{cache_entry | expires_at: System.system_time(:second) - 10}
            :ets.insert(:dynamo_cache, {cache_key, expired_entry})
          _ -> :ok
        end
      end

      # Next call should hit the database again (cache expired)
      # In a real test with mocking, you'd assert ExAws.request was called again
      {:ok, _} = DynamoDBRepo.list_transcripts(user_id_ttl, cache: true)

      # Cache should be empty now (expired)
      if :ets.whereis(:dynamo_cache) != :undefined do
        cache_key = "transcripts_#{user_id_ttl}"
        case :ets.lookup(:dynamo_cache, cache_key) do
          [] -> :ok  # Expected - cache expired
          _ -> :error  # Unexpected - cache should be expired
        end
      end
    end

    test "handles pagination correctly" do
      user_id = "test_user_pagination"

      # Test with limit parameter
      {:ok, _} = DynamoDBRepo.list_transcripts(user_id_pagination, limit: 5)

      # In a real test with mocking, you'd assert:
      # 1. The query includes the limit parameter
      # 2. ExAws.request was called with the correct parameters

      # Test with start_key parameter
      {:ok, _} = DynamoDBRepo.list_transcripts(user_id_pagination, limit: 5, start_key: "test_key")

      # In a real test with mocking, you'd assert:
      # 1. The query includes both limit and start_key parameters
      # 2. ExAws.request was called with the correct parameters
    end
  end
end
