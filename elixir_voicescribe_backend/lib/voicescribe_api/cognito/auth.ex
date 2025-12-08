defmodule VoiceScribeAPI.Cognito.Auth do
  @moduledoc """
  Module for handling AWS Cognito authentication
  """

  alias ExAws.CognitoIdentityProvider
  require Logger

  @doc """
  Authenticates a user with Cognito using username and password
  Returns {:ok, tokens} or {:error, reason}
  """
  def authenticate_user(username, password) do
    client_id = System.get_env("COGNITO_CLIENT_ID")
    client_secret = System.get_env("COGNITO_CLIENT_SECRET")
    _user_pool_id = System.get_env("COGNITO_USER_POOL_ID")

    auth_params = %{
      auth_flow: "USER_PASSWORD_AUTH",
      client_id: client_id,
      auth_parameters: %{
        USERNAME: username,
        PASSWORD: password
      }
    }

    # Add client secret if available
    auth_params =
      if client_secret do
        secret_hash = calculate_secret_hash(username, client_id, client_secret)
        put_in(auth_params[:auth_parameters]["SECRET_HASH"], secret_hash)
      else
        auth_params
      end

    case CognitoIdentityProvider.initiate_auth(auth_params) do
      {:ok, result} ->
        tokens = %{
          access_token: result["AuthenticationResult"]["AccessToken"],
          id_token: result["AuthenticationResult"]["IdToken"],
          refresh_token: result["AuthenticationResult"]["RefreshToken"],
          expires_in: result["AuthenticationResult"]["ExpiresIn"]
        }
        {:ok, tokens}

      {:error, reason} ->
        Logger.error("Cognito authentication failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Refreshes an access token using a refresh token
  Returns {:ok, tokens} or {:error, reason}
  """
  def refresh_token(refresh_token) do
    client_id = System.get_env("COGNITO_CLIENT_ID")
    client_secret = System.get_env("COGNITO_CLIENT_SECRET")

    auth_params = %{
      client_id: client_id,
      auth_flow: "REFRESH_TOKEN_AUTH",
      auth_parameters: %{
        REFRESH_TOKEN: refresh_token
      }
    }

    # Add client secret if available
    auth_params =
      if client_secret do
        # For refresh token, we need to calculate the secret hash differently
        secret_hash = calculate_refresh_secret_hash(refresh_token, client_id, client_secret)
        put_in(auth_params[:auth_parameters]["SECRET_HASH"], secret_hash)
      else
        auth_params
      end

    case CognitoIdentityProvider.initiate_auth(auth_params) do
      {:ok, result} ->
        tokens = %{
          access_token: result["AuthenticationResult"]["AccessToken"],
          id_token: result["AuthenticationResult"]["IdToken"],
          expires_in: result["AuthenticationResult"]["ExpiresIn"]
        }
        {:ok, tokens}

      {:error, reason} ->
        Logger.error("Cognito token refresh failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Signs up a new user in Cognito
  Returns {:ok, result} or {:error, reason}
  """
  def sign_up(username, password, email) do
    client_id = System.get_env("COGNITO_CLIENT_ID")
    client_secret = System.get_env("COGNITO_CLIENT_SECRET")

    sign_up_params = %{
      client_id: client_id,
      username: username,
      password: password,
      user_attributes: [
        %{Name: "email", Value: email}
      ]
    }

    # Add client secret if available
    sign_up_params =
      if client_secret do
        secret_hash = calculate_secret_hash(username, client_id, client_secret)
        Map.put(sign_up_params, :secret_hash, secret_hash)
      else
        sign_up_params
      end

    case CognitoIdentityProvider.sign_up(sign_up_params) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        Logger.error("Cognito sign up failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Confirms a user registration with confirmation code
  Returns {:ok, result} or {:error, reason}
  """
  def confirm_sign_up(username, confirmation_code) do
    client_id = System.get_env("COGNITO_CLIENT_ID")
    client_secret = System.get_env("COGNITO_CLIENT_SECRET")

    confirm_params = %{
      client_id: client_id,
      username: username,
      confirmation_code: confirmation_code
    }

    # Add client secret if available
    confirm_params =
      if client_secret do
        secret_hash = calculate_secret_hash(username, client_id, client_secret)
        Map.put(confirm_params, :secret_hash, secret_hash)
      else
        confirm_params
      end

    case CognitoIdentityProvider.confirm_sign_up(confirm_params) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        Logger.error("Cognito sign up confirmation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Signs out a user from all devices
  Returns {:ok, result} or {:error, reason}
  """
  def global_sign_out(access_token) do
    case CognitoIdentityProvider.global_sign_out(%{access_token: access_token}) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        Logger.error("Cognito global sign out failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp calculate_secret_hash(username, client_id, client_secret) do
    :crypto.mac(:hmac, :sha256, client_secret, "#{username}#{client_id}")
    |> Base.encode64()
  end

  defp calculate_refresh_secret_hash(refresh_token, client_id, client_secret) do
    :crypto.mac(:hmac, :sha256, client_secret, "#{refresh_token}#{client_id}")
    |> Base.encode64()
  end
end
