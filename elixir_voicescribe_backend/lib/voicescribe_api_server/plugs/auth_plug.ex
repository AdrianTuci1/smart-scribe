defmodule VoiceScribeAPIServer.AuthenticationPlug do
  import Plug.Conn
  import Phoenix.Controller
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- verify_token(token) do
      assign(conn, :current_user, claims["sub"])
    else
      _ ->
        conn
          |> put_status(:unauthorized)
          |> json(%{error: "Unauthorized"})
          |> halt()
    end
  end

  defp verify_token(token) do
    # Get Cognito configuration from environment variables
    user_pool_id = System.get_env("COGNITO_USER_POOL_ID")
    region = System.get_env("AWS_REGION", "eu-central-1")

    if user_pool_id do
      # In production, verify JWT signature from Cognito
      # For now, we'll decode without verification to get the user info
      # TODO: Implement proper JWT verification with Cognito public keys
      case decode_jwt(token) do
        {:ok, claims} ->
          # Verify token is not expired
          verify_expiration(claims)
        {:error, reason} ->
          Logger.error("JWT decode error: #{inspect(reason)}")
          {:error, :invalid_token}
      end
    else
      # Fallback for development when Cognito is not configured
      Logger.warn("Cognito not configured, using mock user")
      {:ok, %{"sub" => "mvp-test-user"}}
    end
  end

  defp decode_jwt(token) do
    try do
      # Split token into parts
      [header, payload, _signature] = String.split(token, ".")

      # Decode payload (base64url)
      padded_payload = case rem(byte_size(payload), 4) do
        0 -> payload
        r -> payload <> String.duplicate("=", 4 - r)
      end

      decoded_payload = Base.url_decode64(padded_payload, padding: false)

      case Jason.decode(decoded_payload) do
        {:ok, claims} -> {:ok, claims}
        {:error, _} -> {:error, :invalid_json}
      end
    rescue
      _ -> {:error, :invalid_format}
    end
  end

  defp verify_expiration(claims) do
    case claims do
      %{"exp" => exp} when is_number(exp) ->
        current_time = System.system_time(:second)
        if exp > current_time do
          {:ok, claims}
        else
          {:error, :token_expired}
        end
      _ ->
        # If no expiration claim, assume valid (for development)
        {:ok, claims}
    end
  end
end
