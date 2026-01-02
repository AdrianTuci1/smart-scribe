defmodule VoiceScribeAPIServer.ReferralController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo

  def get_referral_info(conn, _params) do
    user_id = conn.assigns.current_user_id

    # Check if user already has a referral code
    case DynamoDBRepo.get_config(user_id, "referral") do
      %{"referralCode" => code} = config ->
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

  defp generate_referral_code do
    # Generate a random 8-character string (A-Z, 0-9)
    # Using crypto for randomness
    :crypto.strong_rand_bytes(5)
    |> Base.encode32(padding: false)
    |> String.split_at(7)
    |> elem(0)
  end
end
