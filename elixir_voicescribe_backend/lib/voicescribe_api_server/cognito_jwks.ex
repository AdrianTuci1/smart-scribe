defmodule VoiceScribeAPI.CognitoJWKS do
  @moduledoc """
  Modul pentru descărcarea și cache-uirea cheilor JWKS de la AWS Cognito
  """

  require Logger

  @jwks_url "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_KUaE0MTcQ/.well-known/jwks.json"

  def fetch_keys do
    case :ets.lookup(:jwks_cache, :keys) do
      [{:keys, keys}] ->
        Logger.debug("Using cached JWKS keys")
        keys
      _ ->
        Logger.info("Fetching JWKS keys from #{@jwks_url}")

        case HTTPoison.get(@jwks_url) do
          {:ok, %{body: body}} ->
            keys = Jason.decode!(body)
            Logger.debug("Successfully fetched and decoded JWKS keys")
            :ets.insert(:jwks_cache, {:keys, keys})
            keys

          {:error, reason} ->
            Logger.error("Failed to fetch JWKS keys: #{inspect(reason)}")
            raise "Failed to fetch JWKS keys: #{inspect(reason)}"
        end
    end
  end
end
