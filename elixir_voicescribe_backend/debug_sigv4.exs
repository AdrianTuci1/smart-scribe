defmodule SigV4Debug do
  def run do
    region = "eu-central-1"
    access_key = "AKIA4SZHNY2AGOBWDY5J" # From log
    secret_key = "dummy"

    # Fixed time from log: 20251215T040411Z
    amz_date = "20251215T040411Z"
    datestamp = "20251215"

    method = "GET"
    service = "transcribe"
    host = "transcribestreaming.#{region}.amazonaws.com"
    endpoint = "wss://#{host}:8443/stream-transcription-websocket"

    query_params = %{
      "language-code" => "ro-RO",
      "media-encoding" => "pcm",
      "sample-rate" => "16000",
      "show-speaker-label" => "false",
      "enable-partial-results-stabilization" => "true",
      "partial-results-stability" => "low"
    }

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

    auth_params = %{
      "X-Amz-Algorithm" => "AWS4-HMAC-SHA256",
      "X-Amz-Credential" => "#{access_key}/#{credential_scope}",
      "X-Amz-Date" => amz_date,
      "X-Amz-Expires" => "300",
      "X-Amz-SignedHeaders" => signed_headers
    }

    all_params = Map.merge(query_params, auth_params)

    canonical_querystring =
      all_params
      |> Enum.sort()
      |> Enum.map(fn {k, v} -> "#{URI.encode_www_form(k)}=#{URI.encode_www_form(v)}" end)
      |> Enum.join("&")

    payload_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

    canonical_request =
      "#{method}\n#{canonical_uri}\n#{canonical_querystring}\n#{canonical_headers}\n#{signed_headers}\n#{payload_hash}"

    IO.puts "--- Canonical String Produced ---"
    IO.puts canonical_request
    IO.puts "---------------------------------"
  end
end

SigV4Debug.run()
