defmodule VoiceScribeAPIServer.NotificationController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  # GET /notifications
  def index(conn, _params) do
    user_id = conn.assigns.current_user
    notifications = DynamoDBRepo.list_notifications(user_id)
    json(conn, notifications)
  end

  # POST /notifications/:id/action
  def perform_action(conn, %{"id" => notification_id, "action" => action}) do
    user_id = conn.assigns.current_user

    # In list_notifications, we returned items which have 'configType' (id is usually inside data or constructed).
    # Ideally the frontend sends back the `configType` or we reconstruct it if `id` is part of it.
    # Our `create_notification` makes `configType` = "notification_" <> timestamp <> "_" <> id.
    # The frontend only sees what we sent.
    # Let's assume frontend passes the `configType` as the ID since that's the unique key in Dynamo for us here.
    # OR we scan. But we should just send `configType` as `id` or `key` to frontend.

    case action do
      "read" ->
        DynamoDBRepo.update_notification_status(user_id, notification_id, "read")
        json(conn, %{success: true})

      "accept" ->
        # Handle "team_invite" acceptance
        # We need to fetch the notification to see the data
        # For MVP, we can iterate list_notifications or just look it up if we knew the timestamp.
        # Let's assume we can fetch it. If we can't efficiently get single item, we list and find.
        notifications = DynamoDBRepo.list_notifications(user_id)
        notification = Enum.find(notifications, fn n -> n["configType"] == notification_id end)

        if notification && notification["type"] == "team_invite" do
          team_id = notification["data"]["teamId"]

          # Update User Settings with new Team ID
          settings = DynamoDBRepo.get_config(user_id, "settings")
          new_settings = Map.put(settings, "teamId", team_id)
          DynamoDBRepo.put_config(user_id, "settings", new_settings)

          # Add User to Team Metadata (members list)
          # We need to read-modify-write Team Metadata. Race conditions possible but acceptable for MVP.
          team_meta = DynamoDBRepo.get_config("TEAM_" <> team_id, "metadata")
          members = Map.get(team_meta, "members", [])

          # Check if already member
          unless Enum.any?(members, fn m -> m["id"] == user_id end) do
            # Provide some user details (email).
            # We might not have email handy unless in settings?
            email = Map.get(settings, "email", "Unknown")

            new_member = %{
              "id" => user_id,
              "email" => email,
              "status" => "active",
              "joinedAt" => DateTime.utc_now() |> DateTime.to_iso8601()
            }

            new_members = members ++ [new_member]

            DynamoDBRepo.put_config(
              "TEAM_" <> team_id,
              "metadata",
              Map.put(team_meta, "members", new_members)
            )
          end

          # Mark notification as actioned/read
          DynamoDBRepo.update_notification_status(user_id, notification_id, "actioned")

          json(conn, %{success: true, message: "Joined team successfully"})
        else
          conn |> put_status(:bad_request) |> json(%{error: "Invalid notification or action"})
        end

      "deny" ->
        DynamoDBRepo.update_notification_status(user_id, notification_id, "denied")
        json(conn, %{success: true})

      _ ->
        json(conn, %{error: "Unknown action"})
    end
  end
end
