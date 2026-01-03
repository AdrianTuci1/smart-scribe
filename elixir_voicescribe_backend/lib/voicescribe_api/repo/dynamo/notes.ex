defmodule VoiceScribeAPI.Repo.Dynamo.Notes do
  @moduledoc """
  DynamoDB operations for Notes
  """
  alias ExAws.Dynamo

  @notes_table "NotesTable"

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

  def list_all_notes(user_id) do
    # Use ExAws.stream! to automatically handle pagination and fetch all items
    Dynamo.query(@notes_table,
      expression_attribute_values: [userId: user_id],
      key_condition_expression: "userId = :userId"
    )
    |> ExAws.stream!()
    |> Enum.to_list()
  end

  def delete_note(user_id, note_id) do
    Dynamo.delete_item(@notes_table, %{userId: user_id, noteId: note_id}) |> ExAws.request()
  end
end
