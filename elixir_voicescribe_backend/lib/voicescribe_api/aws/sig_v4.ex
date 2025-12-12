defmodule VoiceScribeAPI.AWS.SigV4 do
  @moduledoc """
  Handles AWS Signature V4 signing for WebSocket connections to AWS Transcribe.
  Based on AWS documentation and standard SigV4 implementation.
  """

  def presigned_url(region, access_key, secret_key, session_token \\ nil) do
    method = "GET"
    service = "transcribe"
    host = "transcribestreaming.#{region}.amazonaws.com"
    endpoint = "wss://#{host}:8443/stream-transcription-websocket"

    # Date handling
    now = DateTime.utc_now()
    amz_date = Calendar.strftime(now, "%Y%m%dT%H%M%SZ")
    datestamp = Calendar.strftime(now, "%Y%m%d")

    # Query Parameters
    # Standard params for Transcribe
    query_params = %{
      "language-code" => "ro-RO",
      "media-encoding" => "pcm",
      "sample-rate" => "16000",
      "show-speaker-label" => "false",
      "enable-partial-results-stabilization" => "true",
      "partial-results-stability" => "low"
    }

    # Add SigV4 standard params
    credential_scope = "#{datestamp}/#{region}/#{service}/aws4_request"

    headers = %{
      "host" => host
    }

    # Create Canonical Request
    canonical_uri = "/stream-transcription-websocket"

    canonical_headers =
      headers
      |> Enum.sort()
      |> Enum.map(fn {k, v} -> "#{String.downcase(k)}:#{String.trim(v)}\n" end)
      |> Enum.join("")

    signed_headers =
      headers
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(&String.downcase/1)
      |> Enum.join(";")

    # Start building canonical query string (excluding signature)
    auth_params = %{
      "X-Amz-Algorithm" => "AWS4-HMAC-SHA256",
      "X-Amz-Credential" => "#{access_key}/#{credential_scope}",
      "X-Amz-Date" => amz_date,
      # 5 minutes
      "X-Amz-Expires" => "300",
      "X-Amz-SignedHeaders" => signed_headers
    }

    auth_params =
      if session_token,
        do: Map.put(auth_params, "X-Amz-Security-Token", session_token),
        else: auth_params

    # Combine all params
    all_params = Map.merge(query_params, auth_params)

    canonical_querystring =
      all_params
      |> Enum.sort()
      |> Enum.map(fn {k, v} -> "#{URI.encode_www_form(k)}=#{URI.encode_www_form(v)}" end)
      |> Enum.join("&")

    # Empty string hash
    payload_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

    canonical_request =
      "#{method}\n#{canonical_uri}\n#{canonical_querystring}\n#{canonical_headers}\n#{signed_headers}\n#{payload_hash}"

    # String to Sign
    algorithm = "AWS4-HMAC-SHA256"

    string_to_sign =
      "#{algorithm}\n#{amz_date}\n#{credential_scope}\n#{:crypto.hash(:sha256, canonical_request) |> Base.encode16(case: :lower)}"

    # Derive Signing Key
    k_date = sign("AWS4" <> secret_key, datestamp)
    k_region = sign(k_date, region)
    k_service = sign(k_region, service)
    k_signing = sign(k_service, "aws4_request")

    # Calculate Signature
    signature = sign(k_signing, string_to_sign) |> Base.encode16(case: :lower)

    # Final URL
    "#{endpoint}?#{canonical_querystring}&X-Amz-Signature=#{signature}"
  end

  defp sign(key, msg) do
    :crypto.mac(:hmac, :sha256, key, msg)
  end
end
