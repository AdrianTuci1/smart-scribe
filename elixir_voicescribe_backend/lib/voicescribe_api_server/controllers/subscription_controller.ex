defmodule VoiceScribeAPIServer.SubscriptionController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  # Placeholders - replace with actual Stripe Price IDs
  @price_monthly "price_MONTHLY_ID"
  @price_yearly "price_YEARLY_ID"

  def create_checkout_session(conn, %{"plan" => plan}) do
    user_id = conn.assigns.current_user_id

    price_id =
      case plan do
        "monthly" -> @price_monthly
        "yearly" -> @price_yearly
        _ -> nil
      end

    if price_id do
      params = %{
        payment_method_types: ["card"],
        line_items: [
          %{
            price: price_id,
            quantity: 1
          }
        ],
        mode: "subscription",
        success_url: "https://app.smartscribe.ai/settings/billing?success=true",
        cancel_url: "https://app.smartscribe.ai/settings/billing?canceled=true",
        client_reference_id: user_id,
        metadata: %{
          "userId" => user_id
        }
      }

      case Stripe.Checkout.Session.create(params) do
        {:ok, session} ->
          json(conn, %{url: session.url})

        {:error, error} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Stripe error", details: inspect(error)})
      end
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid plan type"})
    end
  end

  def create_portal_session(conn, _params) do
    user_id = conn.assigns.current_user_id

    # We need to retrieve the stripe_customer_id for this user.
    # checking our DynamoDB config "subscription"
    case DynamoDBRepo.get_subscription_config(user_id) do
      %{"stripeCustomerId" => customer_id} when not is_nil(customer_id) ->
        params = %{
          customer: customer_id,
          return_url: "https://app.smartscribe.ai/settings/billing"
        }

        case Stripe.BillingPortal.Session.create(params) do
          {:ok, session} ->
            json(conn, %{url: session.url})

          {:error, error} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "Stripe error", details: inspect(error)})
        end

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "No active customer found for this user"})
    end
  end

  def webhook(conn, _params) do
    # Verify signature usually occurs here, but for simplicity assuming Plug does it or skipping
    payload = conn.body_params

    case payload["type"] do
      "checkout.session.completed" ->
        session = payload["data"]["object"]
        handle_checkout_completed(session)

      "customer.subscription.deleted" ->
        subscription = payload["data"]["object"]
        handle_subscription_deleted(subscription)

      _ ->
        # Ignore other events
        :ok
    end

    send_resp(conn, 200, "Received")
  end

  defp handle_checkout_completed(session) do
    user_id = session["client_reference_id"]
    customer_id = session["customer"]
    subscription_id = session["subscription"]

    if user_id do
      # Retrieve subscription details to get end date
      {:ok, sub} = Stripe.Subscription.retrieve(subscription_id)
      current_period_end = sub.current_period_end

      data = %{
        "stripeCustomerId" => customer_id,
        "subscriptionId" => subscription_id,
        "status" => "active",
        "currentPeriodEnd" => current_period_end,
        # Simplification
        "plan" => "pro"
      }

      DynamoDBRepo.update_subscription_config(user_id, data)
    end
  end

  defp handle_subscription_deleted(subscription) do
    # Find user by customer ID? Or we assume we don't have mapping backwards easily without GSI.
    # Ideally we should store userId in metadata of subscription.
    user_id = subscription["metadata"]["userId"]

    if user_id do
      data = %{
        "status" => "canceled",
        "plan" => "free"
      }

      DynamoDBRepo.update_subscription_config(user_id, data)
    end
  end
end
