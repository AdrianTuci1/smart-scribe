defmodule VoiceScribeAPI.AI.BedrockClient do
  require Logger
  alias VoiceScribeAPI.DynamoDBRepo

  @model_id "anthropic.claude-haiku-4-5-20251001-v1:0"

  def correct_text(user_id, text) do
    # Fetch dictionary
    dictionary = case DynamoDBRepo.get_config(user_id, "dictionary") do
      empty_map when empty_map == %{} -> %{"rules" => "No custom rules."}
      {:ok, %{"Item" => item}} -> ExAws.Dynamo.decode_item(item)
      _ -> %{"rules" => "No custom rules."}
    end

    # Fetch style preferences
    style_prefs = case DynamoDBRepo.get_config(user_id, "style_preferences") do
      empty_map when empty_map == %{} -> %{"context" => "No specific context", "style" => "No specific style"}
      {:ok, %{"Item" => item}} -> ExAws.Dynamo.decode_item(item)
      _ -> %{"context" => "No specific context", "style" => "No specific style"}
    end

    # Fetch snippets
    snippets = case DynamoDBRepo.get_config(user_id, "snippets") do
      empty_map when empty_map == %{} -> %{"snippets" => []}
      {:ok, %{"Item" => item}} -> ExAws.Dynamo.decode_item(item)
      _ -> %{"snippets" => []}
    end

    rules = Map.get(dictionary, "rules", "No custom rules.")
    style_guidelines = case style_prefs do
      %{"context" => context, "style" => style} ->
        "Context: #{context}, Style: #{style}"
      _ ->
        "No specific style preferences."
    end

    # Format snippets for use in the prompt
    snippets_context = case snippets do
      %{"snippets" => snippet_list} when is_list(snippet_list) and length(snippet_list) > 0 ->
        snippet_list
        |> Enum.map(fn snippet ->
          title = Map.get(snippet, "title", "Untitled")
          content = Map.get(snippet, "content", "")
          "Title: #{title}\nContent: #{content}"
        end)
        |> Enum.join("\n\n---\n\n")
      _ -> "No snippets available."
    end

    system_prompt = "You are an expert AI voice assistant. Your task is to transcribe, correct, and translate user's voice input into clear, professional text for the language specified. Apply the following dictionary corrections if applicable: #{rules}. Apply these style guidelines: #{style_guidelines}. Reference the provided snippets for context and formatting when relevant. Do not add any conversational filler. Output ONLY the final text."

    user_message = """
    Input text: #{text}

    Style guidelines: #{style_guidelines}

    Reference snippets:
    #{snippets_context}

    Instructions:
    1. Correct any grammatical errors.
    2. Apply dictionary corrections above.
    3. Apply style guidelines above.
    4. Reference the snippets for context and formatting when relevant.
    5. Return ONLY the result.
    """

    Logger.info("Sending text to Bedrock for correction: #{String.slice(text, 0, 20)}...")

    body = Jason.encode!(%{
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: 1000,
      temperature: 0.1, # Lower temperature for more precise/deterministic results
      system: system_prompt,
      messages: [%{role: "user", content: user_message}]
    })

    op = %ExAws.Operation.JSON{
      http_method: :post,
      headers: [{"content-type", "application/json"}],
      path: "/model/#{@model_id}/invoke",
      data: body,
      service: :bedrock_runtime
    }

    ExAws.request(op, config_overrides())
    |> case do
      {:ok, %{body: resp_body}} ->
        decoded = Jason.decode!(resp_body)
        content = hd(decoded["content"])["text"]
        Logger.info("Received correction from Bedrock")
        {:ok, content}
      error ->
        Logger.error("Bedrock call failed: #{inspect(error)}")
        {:error, error}
    end
  end

  def save_dictionary(user_id, entries) do
    data = %{
      "rules" => extract_rules_from_entries(entries),
      "entries" => entries
    }

    DynamoDBRepo.put_config(user_id, "dictionary", data)
  end

  def save_style_preferences(user_id, context, style) do
    data = %{
      "context" => context,
      "style" => style
    }

    DynamoDBRepo.put_config(user_id, "style_preferences", data)
  end

  def save_snippets(user_id, snippets) do
    data = %{
      "snippets" => snippets
    }

    DynamoDBRepo.put_config(user_id, "snippets", data)
  end

  defp extract_rules_from_entries(entries) do
    entries
    |> Enum.map(fn entry ->
      "\"#{entry["incorrect_word"]}\" => \"#{entry["correct_word"]}\""
    end)
    |> Enum.join(", ")
  end

  defp config_overrides do
    %{
      host: "bedrock-runtime.#{region()}.amazonaws.com",
      scheme: "https",
      region: region(),
      service: "bedrock",
      port: 443
    }
  end

  defp region do
    System.get_env("AWS_REGION", "eu-central-1")
  end
end
