defmodule VoiceScribeAPIServer.AuthController do
  @moduledoc """
  Controller for handling authentication validation with AWS Cognito
  Swift frontend handles direct Cognito login, backend only validates tokens
  """

  use Phoenix.Controller
  require Logger
  alias VoiceScribeAPI.CognitoAuth

  @doc """
  Validates a JWT token received from Swift frontend
  Swift frontend handles direct Cognito authentication and sends access token
  """
  def validate_token(conn, %{"token" => token}) do
    case CognitoAuth.verify(token) do
      {:ok, claims} ->
        json(conn, %{
          valid: true,
          user_id: claims["sub"],
          message: "Token is valid"
        })
      {:error, reason} ->
        Logger.error("Token validation failed: #{inspect(reason)}")
        conn
        |> put_status(:unauthorized)
        |> json(%{
          valid: false,
          error: "Invalid token"
        })
    end
  end

  @doc """
  Refreshes a JWT token
  Swift frontend can use this endpoint to refresh an expired token
  """
  def refresh_token(conn, %{"refresh_token" => refresh_token}) do
    # In a real implementation, you would validate the refresh token with Cognito
    # For now, we'll just return a mock response
    if refresh_token do
      json(conn, %{
        message: "Token refresh not implemented yet"
      })
    else
      conn
        |> put_status(:bad_request)
        |> json(%{error: "Refresh token is required"})
    end
  end

  @doc """
  Logs out a user by invalidating their token
  Swift frontend can use this to properly log out a user
  """
  def logout(conn, %{"token" => token}) do
    # In a real implementation, you might want to add the token to a blacklist
    # For now, we'll just return a success response
    if token do
      json(conn, %{
        message: "Logged out successfully"
      })
    else
      conn
        |> put_status(:bad_request)
        |> json(%{error: "Token is required"})
    end
  end
end
