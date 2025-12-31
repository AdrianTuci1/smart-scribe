defmodule VoiceScribeAPIServer.Endpoint do
  use Phoenix.Endpoint, otp_app: :voicescribe_api

  socket("/socket", VoiceScribeAPIServer.UserSocket)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(CORSPlug, origin: ["http://localhost:5174", "http://localhost:4000"])
  plug(VoiceScribeAPIServer.Router)
end
