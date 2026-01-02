defmodule VoiceScribeAPI.DynamoDBRepo do
  @moduledoc """
  Main entry point for DynamoDB operations.
  Refactored to delegate to specific context modules.
  """
  alias VoiceScribeAPI.Repo.Dynamo.{Support, Notes, Config, Transcripts, Utils, Notifications}
  alias ExAws.Dynamo

  # -- Delegation --

  # Utils
  defdelegate decode_item(item), to: Utils

  # Support (Invitations & Tickets)
  defdelegate create_invitation(invite), to: Support
  defdelegate get_invitation(invite_code), to: Support
  defdelegate create_ticket(ticket), to: Support
  defdelegate list_user_tickets(user_id), to: Support

  # Subscription
  defdelegate get_subscription_config(user_id), to: Config
  defdelegate update_subscription_config(user_id, data), to: Config

  # Notes
  defdelegate create_note(user_id, note_id, note_data), to: Notes
  defdelegate get_note(user_id, note_id), to: Notes
  defdelegate list_notes(user_id), to: Notes
  defdelegate delete_note(user_id, note_id), to: Notes

  # Config
  defdelegate get_config(user_id, config_type), to: Config
  defdelegate put_config(user_id, config_type, data), to: Config
  defdelegate get_dictionary_entries(user_id), to: Config
  defdelegate put_dictionary_entry(user_id, entry), to: Config
  defdelegate delete_dictionary_entry(user_id, incorrect_word), to: Config
  defdelegate get_usage(user_id), to: Config
  defdelegate update_usage(user_id, word_count), to: Config

  # Transcripts
  defdelegate create_transcript(user_id, transcript_id, transcript_data), to: Transcripts
  defdelegate get_transcript(user_id, transcript_id), to: Transcripts
  defdelegate list_transcripts(user_id, opts \\ []), to: Transcripts
  defdelegate update_transcript(user_id, transcript_id, transcript_data), to: Transcripts
  defdelegate delete_transcript(user_id, transcript_id), to: Transcripts
  defdelegate save_transcript(transcript), to: Transcripts

  # Notifications
  defdelegate list_notifications(user_id), to: Notifications
  defdelegate create_notification(user_id, title, message, type, data \\ %{}), to: Notifications
  defdelegate update_notification_status(user_id, config_type, status), to: Notifications

  # User Lookup
  defdelegate get_user_by_email(email), to: Config

  # -- Orchestration --

  @config_table "UserConfigsTable"

  # User Data Cleanup
  def delete_user_data(user_id) do
    # 1. Delete all Transcripts
    case Transcripts.list_transcripts(user_id, limit: 1000, cache: false) do
      {:ok, %{"Items" => items}} ->
        Enum.each(items, fn item ->
          item = Utils.decode_item(item)
          Transcripts.delete_transcript(user_id, item["transcriptId"])
        end)

      _ ->
        :ok
    end

    # 2. Delete all Notes
    case Notes.list_notes(user_id) do
      {:ok, %{"Items" => items}} ->
        Enum.each(items, fn item ->
          item = Utils.decode_item(item)
          Notes.delete_note(user_id, item["noteId"])
        end)

      _ ->
        :ok
    end

    # 3. Delete all Configs
    # Queries table by userId partition key
    # Ideally should be in Config module, but kept here for now or moved to Config module later
    Dynamo.query(@config_table,
      expression_attribute_values: [userId: user_id],
      key_condition_expression: "userId = :userId"
    )
    |> ExAws.request()
    |> case do
      {:ok, %{"Items" => items}} ->
        Enum.each(items, fn item ->
          item = Utils.decode_item(item)
          # Assuming configType is the Sort Key, delete directly
          Dynamo.delete_item(@config_table, %{userId: user_id, configType: item["configType"]})
          |> ExAws.request()
        end)

      _ ->
        :ok
    end

    # 4. Clear Cache
    Transcripts.delete_cached_transcripts(user_id)

    :ok
  end
end
