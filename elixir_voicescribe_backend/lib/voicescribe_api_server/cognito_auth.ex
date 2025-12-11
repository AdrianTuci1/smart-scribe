defmodule VoiceScribeAPI.CognitoAuth do
  @moduledoc """
  Modul pentru validarea token-urilor Cognito
  """

  alias VoiceScribeAPI.CognitoJWKS
  require Logger

  @issuer "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_KUaE0MTcQ"

  def verify(token) do
    Logger.debug("Verifying token: #{String.slice(token, 0, 20)}...")

    with {:ok, %{"kid" => kid}} <- decode_header(token),
         {:ok, jwk} <- find_jwk(kid),
         {:ok, claims} <- verify_signature(token, jwk),
         :ok <- validate_claims(claims) do
      {:ok, claims}
    else
      error ->
        Logger.error("Token verification failed: #{inspect(error)}")
        {:error, error}
    end
  end

  defp decode_header(token) do
    Logger.debug("Decoding header for token: #{String.slice(token, 0, 20)}...")

    case JOSE.JWT.peek_protected(token) do
      %JOSE.JWS{fields: header} ->
        Logger.debug("Header decoded successfully: #{inspect(header)}")
        {:ok, header}
      %JOSE.JWT{fields: header} ->
        Logger.debug("Header decoded successfully: #{inspect(header)}")
        {:ok, header}
      error ->
        Logger.error("Failed to decode header: #{inspect(error)}")
        {:error, :invalid_header}
    end
  end

  defp find_jwk(kid) do
    Logger.debug("Finding JWK with kid: #{kid}")

    keys = CognitoJWKS.fetch_keys()

    jwk =
      keys["keys"]
      |> Enum.find(fn k -> k["kid"] == kid end)

    if jwk do
      Logger.debug("JWK found successfully")
      {:ok, JOSE.JWK.from_map(jwk)}
    else
      Logger.error("JWK not found for kid: #{kid}")
      {:error, :key_not_found}
    end
  end

  defp verify_signature(token, jwk) do
    Logger.debug("Verifying signature")

    case JOSE.JWT.verify(jwk, token) do
      {true, %JOSE.JWT{fields: claims}, _} ->
        Logger.debug("Signature verified successfully")
        {:ok, claims}

      error ->
        Logger.error("Signature verification failed: #{inspect(error)}")
        {:error, :invalid_signature}
    end
  end

  defp validate_claims(%{"iss" => iss, "exp" => exp}) do
    Logger.debug("Validating claims: iss=#{iss}, exp=#{exp}")

    cond do
      iss != @issuer ->
        Logger.error("Invalid issuer: expected #{@issuer}, got #{iss}")
        {:error, :invalid_issuer}
      exp < System.system_time(:second) ->
        Logger.error("Token expired: exp=#{exp}, current=#{System.system_time(:second)}")
        {:error, :expired}
      true ->
        Logger.debug("Claims validated successfully")
        :ok
    end
  end
end
