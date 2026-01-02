defmodule VoiceScribeAPI.Repo.Dynamo.Notifications do
  alias ExAws.Dynamo
  import VoiceScribeAPI.Repo.Dynamo.Utils

  @config_table "UserConfigsTable"

  def list_notifications(user_id) do
    # Notifications are stored with configType = "notification_<TIMESTAMP>_<UUID>"
    # OR we can store a list in "notifications" configType.
    # Storing as list in single "notifications" config is risky for size limits (400KB).
    # Storing as individual items with sort key "notification#<ID>" would require configType to be the Sort Key.
    # Our schema says configType IS the sort key.
    # So we can use `configType` starting with "notification_".

    Dynamo.query(@config_table,
      expression_attribute_values: [userId: user_id, prefix: "notification_"],
      key_condition_expression: "userId = :userId and begins_with(configType, :prefix)"
    )
    |> ExAws.request()
    |> case do
      {:ok, %{"Items" => items}} ->
        notifications = Enum.map(items, &decode_item/1)
        # Sort by createdAt desc
        Enum.sort_by(notifications, & &1["createdAt"], {:desc, Date})

      _ ->
        []
    end
  end

  def create_notification(user_id, title, message, type, data \\ %{}) do
    id = UUID.uuid4()
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    notification = %{
      "id" => id,
      "title" => title,
      "message" => message,
      # 'team_invite', 'system', 'limit_reached'
      "type" => type,
      "data" => data,
      # unread, read, actioned
      "status" => "unread",
      "createdAt" => timestamp,
      "userId" => user_id,
      "configType" => "notification_" <> timestamp <> "_" <> id
    }

    Dynamo.put_item(@config_table, notification) |> ExAws.request()
  end

  def mark_read(user_id, notification_id, timestamp) do
    # We need the full configType to update.
    # Usually frontend should pass the ID. But we constructed configType from timestamp+id.
    # To avoid scanning, we should probably pass the full ID or timestamp from frontend.
    # For now, let's assume the ID passed IS the configType or we can reconstruct it if we have timestamp.
    # Better: The 'id' returned to frontend should be the 'configType' or include it.

    # Let's assume the 'id' field in the object is just UUID,
    # but the frontend receives the whole object so it has 'configType'.
    # We'll expect 'configType' to be passed as 'id' for this function or we verify.

    # Actually, simpler: define update_status
    nil
  end

  def update_notification_status(user_id, config_type, status) do
    # Verify it belongs to user and is a notification
    if String.starts_with?(config_type, "notification_") do
      # We need to get it first to preserve other fields?
      # DynamoDB UpdateItem is better.
      Dynamo.update_item(
        @config_table,
        %{userId: user_id, configType: config_type},
        update_expression: "SET #s = :status",
        expression_attribute_names: %{"#s" => "status"},
        expression_attribute_values: [status: status]
      )
      |> ExAws.request()
    else
      {:error, :invalid_id}
    end
  end
end
