defmodule VoiceScribeAPI.Repo.Dynamo.Utils do
  @moduledoc """
  Helper functions for DynamoDB operations
  """
  require Logger

  # Helper to decode items with fallback
  def decode_item(item) do
    try do
      ExAws.Dynamo.decode_item(item)
    rescue
      _ ->
        # If decoding fails, try manual decoding
        decode_dynamo_item(item)
    end
  end

  # Helper function to manually decode DynamoDB item format
  def decode_dynamo_item(item) when is_map(item) do
    Enum.reduce(item, %{}, fn {key, value}, acc ->
      decoded_value =
        case value do
          %{"S" => string} -> string
          %{"N" => number} -> number
          %{"L" => list} -> decode_dynamo_list(list)
          %{"M" => nested_map} -> decode_dynamo_item(nested_map)
          %{"BOOL" => boolean} -> boolean
          %{"NULL" => _} -> nil
          _ -> value
        end

      Map.put(acc, key, decoded_value)
    end)
  end

  def decode_dynamo_item(item), do: item

  # Helper function to decode DynamoDB list format
  def decode_dynamo_list(items) when is_list(items) do
    Enum.map(items, fn item ->
      case item do
        %{"S" => string} -> string
        %{"N" => number} -> number
        %{"L" => list} -> decode_dynamo_list(list)
        %{"M" => nested_map} -> decode_dynamo_item(nested_map)
        %{"BOOL" => boolean} -> boolean
        %{"NULL" => _} -> nil
        _ -> item
      end
    end)
  end

  def decode_dynamo_list(_), do: []
end
