defmodule VoiceScribeAPIServer.AuthenticationPlug do
  import Plug.Conn
  import Phoenix.Controller
  require Logger
  alias VoiceScribeAPI.CognitoAuth

  def init(opts), do: opts

  def call(conn, _opts) do
    # Check if auth is disabled via environment variable
    skip_auth = System.get_env("SKIP_AUTH", "false") == "true"

    if skip_auth do
      Logger.info("Authentication is disabled via SKIP_AUTH environment variable")
      # Assign a default user for testing purposes
      assign(conn, :current_user, "test-user")
      |> assign(:cognito_claims, %{"sub" => "test-user"})
    else
      auth_header = get_req_header(conn, "authorization")
      Logger.info("Auth header received")

      with ["Bearer " <> token] <- auth_header do
        Logger.debug("Token extracted: #{String.slice(token, 0, 20)}...")

        case CognitoAuth.verify(token) do
          {:ok, claims} ->
            Logger.info("Authentication successful for user: #{claims["sub"]}")
            assign(conn, :current_user, claims["sub"])
            |> assign(:cognito_claims, claims)

          {:error, reason} ->
            Logger.error("Token verification error: #{inspect(reason)}")
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Token verification failed: #{inspect(reason)}"})
            |> halt()
        end
      else
        [] ->
          Logger.error("No authorization header found")
          conn
            |> put_status(:unauthorized)
            |> json(%{error: "Missing authorization header"})
            |> halt()
        [header] ->
          Logger.error("Invalid authorization header format: #{String.slice(header, 0, 30)}...")
          conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid authorization header format"})
            |> halt()
      end
    end
  end
end
