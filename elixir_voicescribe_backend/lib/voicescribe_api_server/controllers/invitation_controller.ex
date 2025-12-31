defmodule VoiceScribeAPIServer.InvitationController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo
  alias VoiceScribeAPI.Mailer
  import Swoosh.Email

  def create(conn, %{"email" => recipient_email} = _params) do
    user_id = conn.assigns.current_user_id
    # Generate unique invite code
    invite_code = UUID.uuid4()

    invite_data = %{
      "inviteCode" => invite_code,
      "senderId" => user_id,
      "recipientEmail" => recipient_email,
      "status" => "pending",
      "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case DynamoDBRepo.create_invitation(invite_data) do
      {:ok, _} ->
        # Send Email
        send_invite_email(recipient_email, invite_code)

        conn
        |> put_status(:created)
        |> json(%{message: "Invitation sent successfully", inviteCode: invite_code})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to create invitation", details: inspect(reason)})
    end
  end

  def accept(conn, %{"inviteCode" => code}) do
    # Logic to link user or grant benefits
    case DynamoDBRepo.get_invitation(code) do
      {:ok, %{"Item" => item}} when item != nil ->
        # Process acceptance (update status, etc.)
        # For now just return valid
        conn
        |> json(%{message: "Invitation valid", invitation: DynamoDBRepo.decode_item(item)})

      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Invalid invitation code"})
    end
  end

  defp send_invite_email(to_email, code) do
    email =
      new()
      |> to(to_email)
      |> from({"SmartScribe", "no-reply@smartscribe.ai"})
      |> subject("You have been invited to SmartScribe!")
      |> html_body(
        "<h1>Welcome to SmartScribe</h1><p>Use this code to join: <strong>#{code}</strong></p>"
      )
      |> text_body("Welcome to SmartScribe. Use this code to join: #{code}")

    Mailer.deliver(email)
  end
end
