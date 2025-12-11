defmodule VoiceScribeAPIServer.Router do
  use VoiceScribeAPIServer, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  pipeline :auth do
    plug VoiceScribeAPIServer.AuthenticationPlug
  end

  # Authentication routes (no auth required)
  scope "/api/v1", VoiceScribeAPIServer do
    pipe_through [:api]

    post "/auth/validate", AuthController, :validate_token
    post "/auth/refresh", AuthController, :refresh_token
    post "/auth/logout", AuthController, :logout
  end

  # Protected routes (auth required)
  scope "/api/v1", VoiceScribeAPIServer do
    pipe_through [:api, :auth]

    get "/notes", NotesController, :list
    post "/notes", NotesController, :create
    delete "/notes/:id", NotesController, :delete

    get "/config/snippets", ConfigController, :get_config, defaults: %{"type" => "snippets"}
    post "/config/snippets", ConfigController, :put_config, defaults: %{"type" => "snippets"}

    get "/config/dictionary", ConfigController, :get_config, defaults: %{"type" => "dictionary"}
    put "/config/dictionary", ConfigController, :put_config, defaults: %{"type" => "dictionary"}

    # New endpoints for dictionary and style preferences
    post "/config/dictionary/save", ConfigController, :save_dictionary
    post "/config/style_preferences/save", ConfigController, :save_style_preferences
    post "/config/snippets/save", ConfigController, :save_snippets
    get "/config/style_preferences", ConfigController, :get_config, defaults: %{"type" => "style_preferences"}

    # Transcription endpoints
    post "/transcribe/start", TranscribeController, :start_session
    post "/transcribe/chunk", TranscribeController, :upload_chunk
    post "/transcribe/finish", TranscribeController, :finish_session
    get "/transcribe/status", TranscribeController, :get_status

    # Transcript history endpoints
    get "/transcripts", TranscriptsController, :list
    get "/transcripts/:id", TranscriptsController, :show
    post "/transcripts", TranscriptsController, :create
    put "/transcripts/:id", TranscriptsController, :update
    delete "/transcripts/:id", TranscriptsController, :delete
    post "/transcripts/:id/retry", TranscriptsController, :retry
    get "/transcripts/:id/audio", TranscriptsController, :audio_url
  end
end
