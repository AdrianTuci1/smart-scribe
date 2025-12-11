defmodule VoiceScribeAPIServer.ConfigController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo
  alias VoiceScribeAPI.AI.BedrockClient

  def get_config(conn, params) do
    # Extract type from params or use default based on path
    type = Map.get(params, "type", get_default_type_from_path(conn.request_path))

    user_id = conn.assigns.current_user
    result = DynamoDBRepo.get_config(user_id, type)

    # Handle the result from DynamoDBRepo
    case result do
      %{} ->
        # Empty map means no config found
        json(conn, %{data: nil})
      data ->
        # Config found
        json(conn, %{data: data})
    end
  end

  def put_config(conn, params) do
    # Extract type from params or use default based on path
    type = Map.get(params, "type", get_default_type_from_path(conn.request_path))

    user_id = conn.assigns.current_user
    case DynamoDBRepo.put_config(user_id, type, params) do
      {:ok, _} -> json(conn, %{status: "ok"})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  # New endpoints for dictionary and style preferences
  def save_dictionary(conn, %{"entries" => entries}) do
    user_id = conn.assigns.current_user

    case BedrockClient.save_dictionary(user_id, entries) do
      {:ok, _} -> json(conn, %{status: "ok"})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  def save_style_preferences(conn, %{"context" => context, "style" => style}) do
    user_id = conn.assigns.current_user

    case BedrockClient.save_style_preferences(user_id, context, style) do
      {:ok, _} -> json(conn, %{status: "ok"})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  def save_snippets(conn, %{"snippets" => snippets}) do
    user_id = conn.assigns.current_user

    case BedrockClient.save_snippets(user_id, snippets) do
      {:ok, _} -> json(conn, %{status: "ok"})
      {:error, reason} -> json(conn, %{error: inspect(reason)})
    end
  end

  # Helper function to determine type from request path
  defp get_default_type_from_path("/api/v1/config/snippets"), do: "snippets"
  defp get_default_type_from_path("/api/v1/config/dictionary"), do: "dictionary"
  defp get_default_type_from_path("/api/v1/config/style_preferences"), do: "style_preferences"
  defp get_default_type_from_path(_), do: "unknown"
end
