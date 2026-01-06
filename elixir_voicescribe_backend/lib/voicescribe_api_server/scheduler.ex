defmodule VoiceScribeAPIServer.Scheduler do
  use GenServer
  require Logger
  alias VoiceScribeAPI.DynamoDBRepo
  alias VoiceScribeAPI.Emails
  alias VoiceScribeAPI.Mailer
  alias ExAws.Dynamo

  # Run every 24 hours
  @interval 24 * 60 * 60 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    # Schedule first run after 1 minute to let app boot
    Process.send_after(self(), :work, 60_000)
    {:ok, state}
  end

  def handle_info(:work, state) do
    Logger.info("Scheduler running: checking for expiring subscriptions")
    check_expiring_subscriptions()

    # Schedule next run
    Process.send_after(self(), :work, @interval)
    {:noreply, state}
  end

  defp check_expiring_subscriptions do
    # Stream scan for all active subscriptions
    # filter_expression: configType = :ctype AND status = :active
    # configType is 'subscription'

    query =
      Dynamo.scan("UserConfigsTable",
        filter_expression: "configType = :ctype AND #status = :active",
        expression_attribute_names: %{"#status" => "status"},
        expression_attribute_values: [ctype: "subscription", active: "active"]
      )

    query
    |> ExAws.stream!()
    |> Enum.each(&process_subscription/1)
  end

  defp process_subscription(item) do
    # item from stream is already a map of AttributeValues if using low-level,
    # but ExAws usually decodes to simpler map?
    # ExAws.Dynamo.decode_item is needed usually if it returns typed tuples.
    # ExAws streams return raw items usually.
    # Let's use Utils.decode_item via Repo or directly.
    # DynamoDBRepo.decode_item delegates to Utils.
    item = DynamoDBRepo.decode_item(item)

    current_period_end = Map.get(item, "currentPeriodEnd")
    user_id = Map.get(item, "userId")

    if current_period_end && user_id do
      # Check if it expires in 3 days
      now = DateTime.utc_now() |> DateTime.to_unix()
      # current_period_end is unix timestamp
      diff_seconds = current_period_end - now
      days_left = diff_seconds / (60 * 60 * 24)

      # Using range 2.5 to 3.5 days to catch it approximately once per day run
      if days_left >= 2.5 and days_left <= 3.5 do
        send_expiry_email(user_id, round(days_left))
      end
    end
  end

  defp send_expiry_email(user_id, days_left) do
    # We need user email from settings
    settings = DynamoDBRepo.get_config(user_id, "settings")
    email = Map.get(settings, "email")

    if email do
      Logger.info("Sending expiring subscription email to user #{user_id}")
      Emails.subscription_expiring_email(email, days_left) |> Mailer.deliver()
    end
  end
end
