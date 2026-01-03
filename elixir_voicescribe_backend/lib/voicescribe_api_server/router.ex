defmodule VoiceScribeAPIServer.Router do
  use VoiceScribeAPIServer, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth do
    plug(VoiceScribeAPIServer.AuthenticationPlug)
  end

  pipeline :rate_limit do
    plug(VoiceScribeAPIServer.RateLimitPlug, limit: 150)
  end

  # Authentication routes (no auth required)
  scope "/api/v1", VoiceScribeAPIServer do
    pipe_through([:api])

    post("/auth/validate", AuthController, :validate_token)
    post("/auth/refresh", AuthController, :refresh_token)
    post("/auth/logout", AuthController, :logout)
  end

  # Protected routes (auth required)
  scope "/api/v1", VoiceScribeAPIServer do
    pipe_through([:api, :auth, :rate_limit])

    delete("/auth/me", AuthController, :delete_account)

    get("/notes", NotesController, :list)
    post("/notes", NotesController, :create)
    delete("/notes/:id", NotesController, :delete)

    get("/config/snippets", ConfigController, :get_config, defaults: %{"type" => "snippets"})
    post("/config/snippets", ConfigController, :put_config, defaults: %{"type" => "snippets"})

    get("/config/dictionary", ConfigController, :get_config, defaults: %{"type" => "dictionary"})
    put("/config/dictionary", ConfigController, :put_config, defaults: %{"type" => "dictionary"})

    get("/config/settings", ConfigController, :get_config, defaults: %{"type" => "settings"})
    post("/config/settings", ConfigController, :put_config, defaults: %{"type" => "settings"})

    get("/config/onboarding", ConfigController, :get_config, defaults: %{"type" => "onboarding"})
    post("/config/onboarding", ConfigController, :put_config, defaults: %{"type" => "onboarding"})

    # New endpoints for dictionary and style preferences
    post("/config/dictionary/save", ConfigController, :save_dictionary)
    # Granular Dictionary
    post("/config/dictionary/add", ConfigController, :add_dictionary_entry)
    post("/config/dictionary/update", ConfigController, :update_dictionary_entry)
    delete("/config/dictionary/:id", ConfigController, :delete_dictionary_entry)

    post("/config/style_preferences/save", ConfigController, :save_style_preferences)

    post("/config/snippets/save", ConfigController, :save_snippets)
    # Granular Snippets
    post("/config/snippets/add", ConfigController, :add_snippet)
    post("/config/snippets/update", ConfigController, :update_snippet)
    delete("/config/snippets/:id", ConfigController, :delete_snippet)

    get("/config/style_preferences", ConfigController, :get_config,
      defaults: %{"type" => "style_preferences"}
    )

    # Transcript history endpoints
    get("/transcripts", TranscriptsController, :list)
    get("/transcripts/:id", TranscriptsController, :show)
    post("/transcripts", TranscriptsController, :create)
    put("/transcripts/:id", TranscriptsController, :update)
    delete("/transcripts/:id", TranscriptsController, :delete)
    post("/transcripts/:id/retry", TranscriptsController, :retry)
    get("/transcripts/:id/audio", TranscriptsController, :audio_url)

    # Invitations
    post("/invitations", InvitationController, :create)

    # Tickets
    get("/tickets", TicketController, :index)
    post("/tickets", TicketController, :create)

    # Subscriptions
    post("/subscriptions/checkout", SubscriptionController, :create_checkout_session)
    post("/subscriptions/portal", SubscriptionController, :create_portal_session)

    # Referral
    get("/referral", ReferralController, :get_referral_info)

    # Team
    get("/team/members", TeamController, :index)
    post("/team/invite", TeamController, :invite)

    get("/team/shared/:type", TeamController, :shared_items)
    # Keep for now
    post("/team/shared/:type", TeamController, :update_shared_items)

    # Granular Team Shared
    post("/team/shared/:type/add", TeamController, :add_shared_item)
    post("/team/shared/:type/update", TeamController, :update_shared_item)
    delete("/team/shared/:type/:id", TeamController, :delete_shared_item)

    # Notifications
    get("/notifications", NotificationController, :index)
    post("/notifications/:id/action", NotificationController, :perform_action)

    # Stats
    get("/user/stats", StatsController, :index)
  end

  # Public routes
  scope "/api/v1", VoiceScribeAPIServer do
    pipe_through([:api])

    post("/invitations/accept", InvitationController, :accept)
    post("/webhooks/stripe", SubscriptionController, :webhook)
  end
end
