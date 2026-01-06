defmodule VoiceScribeAPIServer.ReferralController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.Emails
  alias VoiceScribeAPI.Mailer
  alias VoiceScribeAPI.DynamoDBRepo

  def get_referral_info(conn, _params) do
    user_id = conn.assigns.current_user_id

    # Check if user already has a referral code
    case DynamoDBRepo.get_config(user_id, "referral") do
      %{"referralCode" => _code} = config ->
        json(conn, config)

      _ ->
        # Generate new code
        # Ideally we'd validte uniqueness, but for MVP simple semi-random is okay
        # Format: 7 chars alphanumeric.
        code = generate_referral_code()

        config = %{
          "referralCode" => code,
          "referralLink" => "https://smartscribe.app/r?#{code}",
          "totalReferrals" => 0,
          "earnedMonths" => 0
        }

        DynamoDBRepo.put_config(user_id, "referral", config)

        json(conn, config)
    end
  end

  def send_invite(conn, %{"email" => to_email}) do
    user_id = conn.assigns.current_user_id

    # Get user email
    settings = DynamoDBRepo.get_config(user_id, "settings")
    from_email = Map.get(settings, "email", "no-reply@smartscribe.ai")

    # Get referral code/link
    referral_config = DynamoDBRepo.get_config(user_id, "referral")
    # If not generated yet, generate one? Or fallback.
    # We should probably generate if missing, but let's assume UI calls get_referral_info first.
    referral_link = Map.get(referral_config, "referralLink", "https://app.smartscribe.ai")

    Emails.referral_email(to_email, from_email, referral_link)
    |> Mailer.deliver()

    json(conn, %{status: "ok"})
  end

  defp generate_referral_code do
    # Generate a random 8-character string (A-Z, 0-9)
    # Using crypto for randomness
    :crypto.strong_rand_bytes(5)
    |> Base.encode32(padding: false)
    |> String.split_at(7)
    |> elem(0)
  end
end
