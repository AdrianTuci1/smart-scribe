defmodule VoiceScribeAPI.AWS.EventStream do
  @moduledoc """
  Handles encoding and decoding of AWS EventStream messages.
  """
  use Bitwise

  @doc """
  Encodes a chunk of audio data into an AudioEvent message.
  """
  def encode_audio_event(audio_data) do
    headers = [
      {":message-type", "event", :string},
      {":event-type", "AudioEvent", :string},
      {":content-type", "application/octet-stream", :string}
    ]

    encoded_headers = encode_headers(headers)
    payload = audio_data

    # Calculate lengths
    headers_len = byte_size(encoded_headers)
    payload_len = byte_size(payload)
    # TotalLen, HeadersLen, PreludeCRC, Headers, Payload, MessageCRC
    total_len = 4 + 4 + 4 + headers_len + payload_len + 4

    # Prelude: TotalLen (4) + HeadersLen (4)
    prelude = <<total_len::big-32, headers_len::big-32>>
    prelude_crc = :erlang.crc32(prelude)

    message_without_crc =
      <<prelude::binary, prelude_crc::big-32, encoded_headers::binary, payload::binary>>

    message_crc = :erlang.crc32(message_without_crc)

    <<message_without_crc::binary, message_crc::big-32>>
  end

  defp encode_headers(headers) do
    Enum.reduce(headers, <<>>, fn {name, value, type}, acc ->
      acc <> encode_header(name, value, type)
    end)
  end

  defp encode_header(name, value, :string) do
    name_len = byte_size(name)
    value_len = byte_size(value)

    # Header format: NameLen(1) + Name + Type(1) + ValueLen(2) + Value
    <<name_len::8, name::binary, 7::8, value_len::big-16, value::binary>>
  end

  @doc """
  Decodes a binary message from AWS Transcribe.
  Simplified to just extract the payload if it's an event.
  """
  def decode_message(binary) do
    try do
      <<total_len::big-32, headers_len::big-32, _prelude_crc::big-32, rest::binary>> = binary

      headers_binary = binary_part(rest, 0, headers_len)
      # Total - (Prelude+CRC) - Headers - MessageCRC
      payload_len = total_len - 12 - headers_len - 4
      payload = binary_part(rest, headers_len, payload_len)

      # Parse headers to check for exception
      headers = parse_headers(headers_binary)

      message_type = Map.get(headers, ":message-type")

      case message_type do
        "event" ->
          {:ok, Jason.decode!(payload)}

        "exception" ->
          {:error, Jason.decode!(payload)}

        _ ->
          {:error, :unknown_message_type}
      end
    rescue
      e -> {:error, {:decoding_error, e}}
    end
  end

  defp parse_headers(binary, acc \\ %{})
  defp parse_headers(<<>>, acc), do: acc

  defp parse_headers(binary, acc) do
    <<name_len::8, rest::binary>> = binary
    <<name::binary-size(name_len), type::8, rest2::binary>> = rest

    {value, rest3} =
      case type do
        # String
        7 ->
          <<val_len::big-16, val::binary-size(val_len), r::binary>> = rest2
          {val, r}

        _ ->
          # For this simplified implementation, we mostly care about strings
          # But we need to handle parsing to consume the binary correctly
          # Assuming string for now as mostly used headers are strings
          <<val_len::big-16, val::binary-size(val_len), r::binary>> = rest2
          {val, r}
      end

    parse_headers(rest3, Map.put(acc, name, value))
  end
end
