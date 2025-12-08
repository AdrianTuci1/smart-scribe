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
  scope "/api/v1/auth", VoiceScribeAPIServer do
    pipe_through :api

    post "/login", AuthController, :login
    post "/signup", AuthController, :sign_up
    post "/confirm", AuthController, :confirm_sign_up
    post "/refresh", AuthController, :refresh_token
  end

  # Protected routes (auth required)
  scope "/api/v1", VoiceScribeAPIServer do
    pipe_through [:api, :auth]

    post "/auth/logout", AuthController, :sign_out

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
  end
end
