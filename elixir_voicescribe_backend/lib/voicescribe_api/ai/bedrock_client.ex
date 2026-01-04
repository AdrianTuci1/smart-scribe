defmodule VoiceScribeAPI.AI.BedrockClient do
  require Logger
  alias VoiceScribeAPI.DynamoDBRepo

  @model_id "us.amazon.nova-lite-v1:0"

  def correct_text(_user_id, text) when is_nil(text) or text == "", do: {:ok, ""}

  def correct_text(user_id, text) do
    if String.trim(text) == "" do
      {:ok, text}
    else
      # Fetch dictionary
      dictionary =
        case DynamoDBRepo.get_config(user_id, "dictionary") do
          empty_map when empty_map == %{} -> %{"rules" => "No custom rules."}
          {:ok, %{"Item" => item}} -> ExAws.Dynamo.decode_item(item)
          _ -> %{"rules" => "No custom rules."}
        end

      # Fetch style preferences
      style_prefs =
        case DynamoDBRepo.get_config(user_id, "style_preferences") do
          empty_map when empty_map == %{} ->
            %{"context" => "No specific context", "style" => "No specific style"}

          {:ok, %{"Item" => item}} ->
            ExAws.Dynamo.decode_item(item)

          _ ->
            %{"context" => "No specific context", "style" => "No specific style"}
        end

      # Fetch snippets
      snippets =
        case DynamoDBRepo.get_config(user_id, "snippets") do
          empty_map when empty_map == %{} -> %{"snippets" => []}
          {:ok, %{"Item" => item}} -> ExAws.Dynamo.decode_item(item)
          _ -> %{"snippets" => []}
        end

      rules = Map.get(dictionary, "rules", "No custom rules.")

      style_guidelines =
        case style_prefs do
          %{"context" => context, "style" => style} ->
            "Context: #{context}, Style: #{style}"

          _ ->
            "No specific style preferences."
        end

      # Format snippets for use in the prompt
      snippets_context =
        case snippets do
          %{"snippets" => snippet_list} when is_list(snippet_list) and length(snippet_list) > 0 ->
            snippet_list
            |> Enum.map(fn snippet ->
              title = Map.get(snippet, "title", "Untitled")
              content = Map.get(snippet, "content", "")
              "Title: #{title}\nContent: #{content}"
            end)
            |> Enum.join("\n\n---\n\n")

          _ ->
            "No snippets available."
        end

      system_prompt =
        "You are an expert AI voice assistant. Your task is to transcribe and correct the user's input into clear, professional text. IMPORTANT instructions: 1. Format times as digits (e.g., 'half past eight' -> '8:30') in any language. 2. Handle uncertainty: if the user changes their mind (e.g., 'let's go to x, or better y'), keep only the final decision ('let's go to y'). 3. Remove filler words (um, er, uh, etc.). 4. Correct spelling and logic errors based on context (e.g., city names). 5. Support mixed languages (e.g., Romanian and English intermixed) but DO NOT TRANSLATE; keep the transcription in the original language. Apply the following dictionary corrections if applicable: #{rules}. Apply these style guidelines: #{style_guidelines}. Reference the provided snippets for context and formatting when relevant. Output ONLY the corrected text. Do NOT include 'Output:' or any other label. Do NOT provide explanations. Revisit the text to ensure it is clear and professional and nothing feels off."

      user_message = """
      Input text: #{text}

      Style guidelines: #{style_guidelines}

      Reference snippets:
      #{snippets_context}
      """

      Logger.info("Sending text to Bedrock for correction: #{String.slice(text, 0, 20)}...")

      body =
        Jason.encode!(%{
          system: [%{text: system_prompt}],
          messages: [%{role: "user", content: [%{text: user_message}]}],
          inferenceConfig: %{max_new_tokens: 4096}
        })

      op = %ExAws.Operation.JSON{
        http_method: :post,
        headers: [{"content-type", "application/json"}],
        path: "/model/#{@model_id}/invoke",
        data: body,
        service: :bedrock
      }

      ExAws.request(op, config_overrides())
      |> case do
        {:ok, %{"output" => %{"message" => %{"content" => content_list}}}} ->
          content = hd(content_list)["text"]
          Logger.info("Received correction from Bedrock")
          {:ok, content}

        {:ok, %{body: resp_body}} ->
          decoded = Jason.decode!(resp_body)

          content =
            case decoded do
              %{"output" => %{"message" => %{"content" => content_list}}} ->
                hd(content_list)["text"]

              _ ->
                # Fallback for standard InvokeModel response if different
                hd(decoded["content"])["text"]
            end

          Logger.info("Received correction from Bedrock (via body)")
          {:ok, content}

        error ->
          Logger.error("Bedrock call failed: #{inspect(error)}")
          {:error, error}
      end
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
    |> Enum.filter(fn entry ->
      incorrect = Map.get(entry, "incorrectWord", Map.get(entry, "incorrect_word", ""))
      correct = Map.get(entry, "correctWord", Map.get(entry, "correct_word", ""))
      # Only include entries where incorrect != correct (actual corrections)
      incorrect != "" and correct != "" and incorrect != correct
    end)
    |> Enum.map(fn entry ->
      incorrect = Map.get(entry, "incorrectWord", Map.get(entry, "incorrect_word", ""))
      correct = Map.get(entry, "correctWord", Map.get(entry, "correct_word", ""))
      "\"#{incorrect}\" => \"#{correct}\""
    end)
    |> Enum.join(", ")
  end

  defp config_overrides do
    overrides = %{
      host: "bedrock-runtime.#{region()}.amazonaws.com",
      scheme: "https",
      region: region(),
      service: :bedrock,
      port: 443
    }

    # Explicitly pass trimmed credentials to ensure they are clean
    case {System.get_env("AWS_ACCESS_KEY_ID"), System.get_env("AWS_SECRET_ACCESS_KEY")} do
      {access_key, secret_key} when is_binary(access_key) and is_binary(secret_key) ->
        Map.merge(overrides, %{
          access_key_id: String.trim(access_key),
          secret_access_key: String.trim(secret_key)
        })

      _ ->
        overrides
    end
  end

  defp region do
    System.get_env("AWS_REGION_BEDROCK", "us-east-1") |> String.trim()
  end
end
