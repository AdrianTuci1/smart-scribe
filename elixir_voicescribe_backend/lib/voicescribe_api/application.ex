defmodule VoiceScribeAPI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VoiceScribeAPIServer.Telemetry,
      {DNSCluster, query: Application.get_env(:voicescribe_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: VoiceScribeAPI.PubSub},
      # Start a worker by calling: VoiceScribeAPI.Worker.start_link(arg)
      # {VoiceScribeAPI.Worker, arg},
      # Start TranscribeGenServer as a named process
      {VoiceScribeAPI.Transcription.TranscribeGenServer, []},
      # Start TranscribeSessionManager
      {VoiceScribeAPI.Transcription.TranscribeSessionManager, []},
      # Start to serve requests, typically the last entry
      VoiceScribeAPIServer.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VoiceScribeAPI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VoiceScribeAPIServer.Endpoint.config_change(changed, removed)
    :ok
  end
end
