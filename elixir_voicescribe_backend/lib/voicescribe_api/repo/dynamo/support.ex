defmodule VoiceScribeAPI.Repo.Dynamo.Support do
  @moduledoc """
  DynamoDB operations for Support features (Invitations, Tickets)
  """
  alias ExAws.Dynamo

  @invitations_table "InvitationsTable"
  @tickets_table "TicketsTable"

  # Invitations
  def create_invitation(invite) do
    Dynamo.put_item(@invitations_table, invite) |> ExAws.request()
  end

  def get_invitation(invite_code) do
    Dynamo.get_item(@invitations_table, %{inviteCode: invite_code}) |> ExAws.request()
  end

  # Tickets
  def create_ticket(ticket) do
    Dynamo.put_item(@tickets_table, ticket) |> ExAws.request()
  end

  def list_user_tickets(user_id) do
    Dynamo.query(@tickets_table,
      expression_attribute_values: [userId: user_id],
      key_condition_expression: "userId = :userId",
      # Assuming GSI on UserId exists or table calls for scan
      index_name: "UserIdIndex"
    )
    |> ExAws.request()
  end
end
