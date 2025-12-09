defmodule VoiceScribeAPI.DynamoDBRepo do
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
    ) |> ExAws.request()
  end

  def delete_note(user_id, note_id) do
    Dynamo.delete_item(@notes_table, %{userId: user_id, noteId: note_id}) |> ExAws.request()
  end

  # Configs
  def get_config(user_id, config_type) do
    case Dynamo.get_item(@config_table, %{userId: user_id, configType: config_type}) |> ExAws.request() do
      {:ok, result} ->
        case result["Item"] do
          nil -> %{}
          item -> ExAws.Dynamo.decode_item(item)
        end
      _error ->
        %{}
    end
  end

  def put_config(user_id, config_type, data) do
    item = Map.merge(data, %{"userId" => user_id, "configType" => config_type})
    Dynamo.put_item(@config_table, item) |> ExAws.request()
  end

  # Dictionary entries
  def get_dictionary_entries(user_id) do
    case Dynamo.get_item(@config_table, %{userId: user_id, configType: "dictionary"}) |> ExAws.request() do
      {:ok, result} ->
        case result["Item"] do
          nil -> []
          item ->
            entries = Map.get(item, "entries", [])
            # Convert entries to a list of dictionaries if needed
            case entries do
              nil -> []
              list when is_list(list) -> list
              _ -> []
            end
        end
      _error ->
        []
    end
  end

  def put_dictionary_entry(user_id, entry) do
    # Get existing dictionary
    case get_dictionary_entries(user_id) do
      entries ->
        new_entry = %{incorrectWord: entry.incorrectWord, correctWord: entry.correctWord, createdAt: DateTime.utc_now()}

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
        updated_entries = Enum.filter(entries, fn entry ->
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
  def create_transcript(user_id, transcript_id, transcript_data) do
    item = Map.merge(transcript_data, %{"userId" => user_id, "transcriptId" => transcript_id})
    Dynamo.put_item(@transcripts_table, item) |> ExAws.request()
  end

  def get_transcript(user_id, transcript_id) do
    Dynamo.get_item(@transcripts_table, %{userId: user_id, transcriptId: transcript_id}) |> ExAws.request()
  end

  def list_transcripts(user_id) do
    try do
      case Dynamo.query(@transcripts_table,
        expression_attribute_values: [userId: user_id],
        key_condition_expression: "userId = :userId"
      ) |> ExAws.request() do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  def update_transcript(user_id, transcript_id, transcript_data) do
    item = Map.merge(transcript_data, %{"userId" => user_id, "transcriptId" => transcript_id})
    Dynamo.put_item(@transcripts_table, item) |> ExAws.request()
  end

  def delete_transcript(user_id, transcript_id) do
    Dynamo.delete_item(@transcripts_table, %{userId: user_id, transcriptId: transcript_id}) |> ExAws.request()
  end
end
