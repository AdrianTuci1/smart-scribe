defmodule VoiceScribeAPIServer.TicketController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  def create(conn, %{"subject" => subject, "message" => message}) do
    user_id = conn.assigns.current_user_id
    ticket_id = UUID.uuid4()

    ticket_data = %{
      "ticketId" => ticket_id,
      "userId" => user_id,
      "subject" => subject,
      "message" => message,
      "status" => "open",
      "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case DynamoDBRepo.create_ticket(ticket_data) do
      {:ok, _} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Ticket created successfully", ticketId: ticket_id})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to create ticket", details: inspect(reason)})
    end
  end

  def index(conn, _params) do
    user_id = conn.assigns.current_user_id

    case DynamoDBRepo.list_user_tickets(user_id) do
      {:ok, %{"Items" => items}} ->
        tickets = Enum.map(items, &DynamoDBRepo.decode_item/1)
        json(conn, %{tickets: tickets})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to list tickets", details: inspect(reason)})
    end
  end
end
