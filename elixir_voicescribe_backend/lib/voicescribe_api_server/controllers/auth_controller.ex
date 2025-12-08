defmodule VoiceScribeAPIServer.AuthController do
  use VoiceScribeAPIServer, :controller

  alias VoiceScribeAPI.Cognito.Auth

  def login(conn, %{"username" => username, "password" => password}) do
    case Auth.authenticate_user(username, password) do
      {:ok, tokens} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          data: %{
            access_token: tokens.access_token,
            id_token: tokens.id_token,
            refresh_token: tokens.refresh_token,
            expires_in: tokens.expires_in
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          success: false,
          error: format_error(reason)
        })
    end
  end

  def refresh_token(conn, %{"refresh_token" => refresh_token}) do
    case Auth.refresh_token(refresh_token) do
      {:ok, tokens} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          data: %{
            access_token: tokens.access_token,
            id_token: tokens.id_token,
            expires_in: tokens.expires_in
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          success: false,
          error: format_error(reason)
        })
    end
  end

  def sign_up(conn, %{"username" => username, "password" => password, "email" => email}) do
    case Auth.sign_up(username, password, email) do
      {:ok, result} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            user_confirmed: result["UserConfirmed"],
            user_sub: result["UserSub"]
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: format_error(reason)
        })
    end
  end

  def confirm_sign_up(conn, %{"username" => username, "confirmation_code" => confirmation_code}) do
    case Auth.confirm_sign_up(username, confirmation_code) do
      {:ok, _result} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "User confirmed successfully"
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: format_error(reason)
        })
    end
  end

  def sign_out(conn, _params) do
    # Get the access token from the authorization header
    with ["Bearer " <> access_token] <- get_req_header(conn, "authorization"),
         {:ok, _result} <- Auth.global_sign_out(access_token) do
      conn
      |> put_status(:ok)
      |> json(%{
        success: true,
        message: "Signed out successfully"
      })
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          success: false,
          error: "Invalid or missing token"
        })
    end
  end

  defp format_error(%{"__type__" => error_type, "message" => message}) do
    # Handle AWS error format
    case error_type do
      "NotAuthorizedException" -> "Invalid username or password"
      "UserNotFoundException" -> "User not found"
      "UserNotConfirmedException" -> "User not confirmed"
      "UsernameExistsException" -> "Username already exists"
      "InvalidParameterException" -> message
      "TooManyRequestsException" -> "Too many requests, please try again later"
      _ -> "Authentication failed"
    end
  end

  defp format_error(_reason) do
    "Authentication failed"
  end
end
