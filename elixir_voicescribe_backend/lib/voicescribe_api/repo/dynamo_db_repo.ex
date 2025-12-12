defmodule VoiceScribeAPI.DynamoDBRepo do
  require Logger
  alias ExAws.Dynamo

  @notes_table "NotesTable"
  @config_table "UserConfigsTable"
  @transcripts_table "TranscriptsTable"

  # Notes
  def create_note(user_id, note_id, note_data) do
    item = Map.merge(note_data, %{"userId" => user_id, "noteId" => note_id})
    Dynamo.put_item(@notes_table, item) |> ExAws.request()
  end

  def get_note(user_id, note_id) do
    Dynamo.get_item(@notes_table, %{userId: user_id, noteId: note_id}) |> ExAws.request()
  end

  def list_notes(user_id) do
    Dynamo.query(@notes_table,
      expression_attribute_values: [userId: user_id],
      key_condition_expression: "userId = :userId"
    )
    |> ExAws.request()
  end

  def delete_note(user_id, note_id) do
    Dynamo.delete_item(@notes_table, %{userId: user_id, noteId: note_id}) |> ExAws.request()
  end

  # Configs
  def get_config(user_id, config_type) do
    case Dynamo.get_item(@config_table, %{userId: user_id, configType: config_type})
         |> ExAws.request() do
      {:ok, result} ->
        case result do
          %{"Item" => item} when item != nil ->
            decode_item(item)

          _ ->
            %{}
        end

      {:error, _reason} ->
        %{}
    end
  end

  def put_config(user_id, config_type, data) do
    item = Map.merge(data, %{"userId" => user_id, "configType" => config_type})
    Dynamo.put_item(@config_table, item) |> ExAws.request()
  end

  # Dictionary entries
  def get_dictionary_entries(user_id) do
    case get_config(user_id, "dictionary") do
      empty_map when empty_map == %{} ->
        []

      config ->
        entries = Map.get(config, "entries", [])
        # Convert entries to a list of dictionaries if needed
        case entries do
          nil -> []
          list when is_list(list) -> list
          _ -> []
        end
    end
  end

  def put_dictionary_entry(user_id, entry) do
    # Get existing dictionary
    case get_dictionary_entries(user_id) do
      entries ->
        new_entry = %{
          incorrectWord: entry.incorrectWord,
          correctWord: entry.correctWord,
          createdAt: DateTime.utc_now()
        }

        # Update entries with new entry
        updated_entries = [new_entry | entries]

        # Save back to DynamoDB
        data = %{
          "userId" => user_id,
          "configType" => "dictionary",
          "entries" => updated_entries
        }

        item = Map.merge(data, %{"configType" => "dictionary", "userId" => user_id})
        Dynamo.put_item(@config_table, item) |> ExAws.request()
    end
  end

  def delete_dictionary_entry(user_id, incorrect_word) do
    case get_dictionary_entries(user_id) do
      entries ->
        # Filter out the entry to delete
        updated_entries =
          Enum.filter(entries, fn entry ->
            entry.incorrectWord != incorrect_word
          end)

        # Save back to DynamoDB
        data = %{
          "userId" => user_id,
          "configType" => "dictionary",
          "entries" => updated_entries
        }

        item = Map.merge(data, %{"configType" => "dictionary", "userId" => user_id})
        Dynamo.put_item(@config_table, item) |> ExAws.request()
    end
  end

  # Transcripts
  # Transcripts
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
    use_cache = Keyword.get(opts, :cache, true)

    try do
      # Check cache first if enabled
      if use_cache do
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
        # Cache the result for future requests
        cache_key = "transcripts_#{user_id}"
        # Cache for 60 seconds
        set_cache(cache_key, result, 60)

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Simple in-memory cache with TTL (in production, use Redis)
  @dynamo_cache :dynamo_cache

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

  # Public helper to decode items with fallback
  def decode_item(item) do
    try do
      ExAws.Dynamo.decode_item(item)
    rescue
      _ ->
        # If decoding fails, try manual decoding
        decode_dynamo_item(item)
    end
  end

  # Helper function to manually decode DynamoDB item format
  defp decode_dynamo_item(item) when is_map(item) do
    Enum.reduce(item, %{}, fn {key, value}, acc ->
      decoded_value =
        case value do
          %{"S" => string} -> string
          %{"N" => number} -> number
          %{"L" => list} -> decode_dynamo_list(list)
          %{"M" => nested_map} -> decode_dynamo_item(nested_map)
          %{"BOOL" => boolean} -> boolean
          %{"NULL" => _} -> nil
          _ -> value
        end

      Map.put(acc, key, decoded_value)
    end)
  end

  defp decode_dynamo_item(item), do: item

  # Helper function to decode DynamoDB list format
  defp decode_dynamo_list(items) when is_list(items) do
    Enum.map(items, fn item ->
      case item do
        %{"S" => string} -> string
        %{"N" => number} -> number
        %{"L" => list} -> decode_dynamo_list(list)
        %{"M" => nested_map} -> decode_dynamo_item(nested_map)
        %{"BOOL" => boolean} -> boolean
        %{"NULL" => _} -> nil
        _ -> item
      end
    end)
  end

  defp decode_dynamo_list(_), do: []
end
