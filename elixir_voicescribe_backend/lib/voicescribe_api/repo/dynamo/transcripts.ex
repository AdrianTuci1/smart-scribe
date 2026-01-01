defmodule VoiceScribeAPI.Repo.Dynamo.Transcripts do
  @moduledoc """
  DynamoDB operations for Transcripts
  """
  require Logger
  alias ExAws.Dynamo

  @transcripts_table "TranscriptsTable"

  # Simple in-memory cache with TTL (in production, use Redis)
  @dynamo_cache :dynamo_cache

  def create_transcript(user_id, transcript_id, transcript_data) do
    delete_cache("transcripts_#{user_id}")
    item = Map.merge(transcript_data, %{"userId" => user_id, "transcriptId" => transcript_id})
    Dynamo.put_item(@transcripts_table, item) |> ExAws.request()
  end

  def get_transcript(user_id, transcript_id) do
    Dynamo.get_item(@transcripts_table, %{userId: user_id, transcriptId: transcript_id})
    |> ExAws.request()
  end

  def list_transcripts(user_id, opts \\ []) do
    # Parse options for pagination and cache
    limit = Keyword.get(opts, :limit, 20)
    start_key = Keyword.get(opts, :start_key, nil)
    # Disable cache by default for now to debug empty response issues and avoid pagination bugs
    use_cache = Keyword.get(opts, :cache, false)

    try do
      # Check cache first if enabled
      if use_cache do
        # Note: This cache key needs to include limit/start_key to be correct
        cache_key = "transcripts_#{user_id}"

        case get_cache(cache_key) do
          {:ok, cached_result} ->
            Logger.debug("Returning cached transcripts for user #{user_id}")
            {:ok, cached_result}

          _ ->
            # Cache miss, proceed with query
            execute_transcripts_query(user_id, limit, start_key)
        end
      else
        # Cache disabled, proceed directly
        execute_transcripts_query(user_id, limit, start_key)
      end
    rescue
      error -> {:error, error}
    end
  end

  defp execute_transcripts_query(user_id, limit, start_key) do
    query_params = %{
      expression_attribute_values: [userId: user_id],
      key_condition_expression: "userId = :userId",
      limit: limit
    }

    # Add start key for pagination if provided
    query_params =
      if start_key do
        Map.put(query_params, :exclusive_start_key, start_key)
      else
        query_params
      end

    query = Dynamo.query(@transcripts_table, query_params)

    case ExAws.request(query) do
      {:ok, result} ->
        count = Map.get(result, "Count", 0)
        Logger.info("DynamoDB Query Success for User #{user_id}. Found #{count} items.")

        # Cache the result for future requests
        # Cache disabled for debugging
        # set_cache(...)

        {:ok, result}

      {:error, reason} ->
        Logger.error("DynamoDB Query Failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def update_transcript(user_id, transcript_id, transcript_data) do
    delete_cache("transcripts_#{user_id}")
    item = Map.merge(transcript_data, %{"userId" => user_id, "transcriptId" => transcript_id})
    Dynamo.put_item(@transcripts_table, item) |> ExAws.request()
  end

  def delete_transcript(user_id, transcript_id) do
    delete_cache("transcripts_#{user_id}")

    Dynamo.delete_item(@transcripts_table, %{userId: user_id, transcriptId: transcript_id})
    |> ExAws.request()
  end

  def save_transcript(transcript) do
    # Convert atom keys to string keys for DynamoDB
    item =
      transcript
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        val =
          case value do
            %DateTime{} -> DateTime.to_iso8601(value)
            _ -> value
          end

        Map.put(acc, to_string(key), val)
      end)

    Dynamo.put_item(@transcripts_table, item) |> ExAws.request()
  end

  # Cache helpers exposed for usage in other modules if needed (like delete logic in Facade)
  def delete_cached_transcripts(user_id) do
    delete_cache("transcripts_#{user_id}")
  end

  # Private Cache Helpers
  defp get_cache(key) do
    if :ets.whereis(@dynamo_cache) == :undefined do
      try do
        :ets.new(@dynamo_cache, [:set, :public, :named_table])
      rescue
        _ -> :ok
      end
    end

    case :ets.lookup(@dynamo_cache, key) do
      [] ->
        :miss

      [{^key, %{value: value, expires_at: expires_at}}] ->
        current_time = System.system_time(:second)

        if current_time < expires_at do
          {:ok, value}
        else
          # Cache expired
          :ets.delete(@dynamo_cache, key)
          :miss
        end
    end
  end

  defp set_cache(key, value, ttl_seconds) do
    if :ets.whereis(@dynamo_cache) == :undefined do
      try do
        :ets.new(@dynamo_cache, [:set, :public, :named_table])
      rescue
        _ -> :ok
      end
    end

    expires_at = System.system_time(:second) + ttl_seconds
    :ets.insert(@dynamo_cache, {key, %{value: value, expires_at: expires_at}})
    :ok
  end

  defp delete_cache(key) do
    if :ets.whereis(@dynamo_cache) != :undefined do
      :ets.delete(@dynamo_cache, key)
    end

    :ok
  end
end
