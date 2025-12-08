defmodule VoiceScribeAPIServer do
  @moduledoc """
  The entrypoint for defining your API interface, such
  as controllers, and so on.

  This can be used in your application as:

      use VoiceScribeAPIServer, :controller

  The definitions below will be executed for every controller,
  so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  defp verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: VoiceScribeAPIServer.Endpoint,
        router: VoiceScribeAPIServer.Router,
        statics: VoiceScribeAPIServer.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
