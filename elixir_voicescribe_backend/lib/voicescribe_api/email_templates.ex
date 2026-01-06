defmodule VoiceScribeAPI.EmailTemplates do
  require EEx

  EEx.function_from_file(:def, :welcome, "lib/voicescribe_api/templates/email/welcome.html.eex", [
    :assigns
  ])

  EEx.function_from_file(
    :def,
    :subscription_expiring,
    "lib/voicescribe_api/templates/email/subscription_expiring.html.eex",
    [:assigns]
  )

  EEx.function_from_file(
    :def,
    :referral,
    "lib/voicescribe_api/templates/email/referral.html.eex",
    [:assigns]
  )
end
