defmodule VoiceScribeAPI.Emails do
  import Swoosh.Email

  @sender_email "no-reply@smartscribe.ai"
  @sender_name "SmartScribe"

  alias VoiceScribeAPI.EmailTemplates

  def welcome_email(to_email) do
    new()
    |> to(to_email)
    |> from({@sender_name, @sender_email})
    |> subject("Welcome to SmartScribe!")
    |> html_body(EmailTemplates.welcome(%{}))
    |> text_body("""
    Welcome to SmartScribe!
    We are excited to have you on board.
    Get started by exploring your dashboard and setting up your preferences.
    Happy scribing!
    """)
  end

  def subscription_expiring_email(to_email, days_left) do
    new()
    |> to(to_email)
    |> from({@sender_name, @sender_email})
    |> subject("Your SmartScribe Pro Plan expires soon")
    |> html_body(EmailTemplates.subscription_expiring(%{days_left: days_left}))
    |> text_body("""
    Your Pro Plan expires in #{days_left} days.
    Don't lose access to your premium features.
    Renew now to keep enjoying SmartScribe Pro: https://app.smartscribe.ai/settings/billing
    """)
  end

  def referral_email(to_email, from_email, referral_link) do
    new()
    |> to(to_email)
    |> from({@sender_name, @sender_email})
    |> reply_to(from_email)
    |> subject("You've been invited to try SmartScribe Pro")
    |> html_body(EmailTemplates.referral(%{from_email: from_email, referral_link: referral_link}))
    |> text_body("""
    You've been invited!
    Your friend (#{from_email}) thinks you'd love SmartScribe.
    Use the link below to get a free month of SmartScribe Pro:
    #{referral_link}
    """)
  end
end
