defmodule VoiceScribeAPI.AI.BedrockClient do
  require Logger
  alias VoiceScribeAPI.DynamoDBRepo

  @model_id "amazon.nova-2-lite-v1:0"

  @system_instructions """
  Context: You are an AI assistant that processes raw audio transcripts.

  CRITICAL CORE RULE: NEVER TRANSLATE THE TEXT. The output MUST be in the EXACT SAME LANGUAGE as the input. If the input is in Romanian, the output MUST be in Romanian. If the input is in English, the output MUST be in English. If the input mixes languages, the output MUST mix languages exactly as spoken.

  Task: Perform Text Sanitization, Disfluency Removal, and Content Correction on the text.

  Specific instructions:
  1. **NO TRANSLATION**: This is the most important rule. Do not translate code-switched terms. "email address" in a Romanian sentence stays "email address".
  2. **Sanitization**: Remove filler words ('ahm', 'um', 'uh'), coughs, and hesitations.
  3. **Disfluency**: Fix stuttering and self-corrections (keep only the final intended phrase).
  4. **Grammar**: Correct grammar and spelling errors ONLY within the original language.
  5. **Dictionary**: STRICTLY apply the provided dictionary rules.
  6. **Style**: Maintain the speaker's original meaning and tone.
  7. **Formatting**: If formatting is requested, apply it while preserving the language.
  """

  def correct_text(_user_id, text) when is_nil(text) or text == "", do: {:ok, ""}

  def correct_text(user_id, text) do
    if String.trim(text) == "" do
      {:ok, text}
    else
      # Fetch dictionary
      dictionary_entries =
        case DynamoDBRepo.get_config(user_id, "dictionary") do
          %{"entries" => entries} when is_list(entries) ->
            Logger.info("Dictionary loaded: #{length(entries)} entries")
            entries

          other ->
            Logger.info("Dictionary load result (fallback): #{inspect(other)}")
            []
        end

      # Fetch style preferences
      style_prefs =
        case DynamoDBRepo.get_config(user_id, "style_preferences") do
          prefs when is_map(prefs) and prefs != %{} ->
            prefs

          _ ->
            %{"context" => "No specific context", "style" => "No specific style"}
        end

      # Fetch snippets
      snippets_list =
        case DynamoDBRepo.get_config(user_id, "snippets") do
          %{"snippets" => snippets} when is_list(snippets) ->
            Logger.info("Snippets loaded: #{length(snippets)} snippets")
            snippets

          other ->
            Logger.info("Snippets load result (fallback): #{inspect(other)}")
            []
        end

      Logger.info(
        "Loaded context for user #{user_id}: Dictionary Entries: #{length(dictionary_entries)}, Snippets: #{length(snippets_list)}"
      )

      style_guidelines =
        case style_prefs do
          %{"context" => context, "style" => style} ->
            "Context: #{context}, Style: #{style}"

          _ ->
            "No specific style preferences."
        end

      # Format Dictionary for Prompt
      # Separating into Rules (Incorrect -> Correct) and Vocabulary (Just Correct words)
      {correction_rules, vocabulary_terms} =
        if length(dictionary_entries) > 0 do
          Enum.reduce(dictionary_entries, {[], []}, fn entry, {rules, vocab} ->
            incorrect = Map.get(entry, "incorrectWord", Map.get(entry, "incorrect_word", ""))
            correct = Map.get(entry, "correctWord", Map.get(entry, "correct_word", ""))

            cond do
              incorrect != "" and correct != "" ->
                {["- Incorrect: \"#{incorrect}\" -> Correct: \"#{correct}\"" | rules], vocab}

              correct != "" ->
                {rules, ["- Term: \"#{correct}\"" | vocab]}

              true ->
                {rules, vocab}
            end
          end)
        else
          {[], []}
        end

      dictionary_rules_context =
        if correction_rules != [],
          do: Enum.join(Enum.reverse(correction_rules), "\n"),
          else: "No specific correction rules."

      vocabulary_context =
        if vocabulary_terms != [],
          do: Enum.join(Enum.reverse(vocabulary_terms), "\n"),
          else: "No specific vocabulary."

      # Format Snippets for Prompt
      snippets_context =
        if length(snippets_list) > 0 do
          snippets_list
          |> Enum.map(fn snippet ->
            title = Map.get(snippet, "title", "Untitled")
            content = Map.get(snippet, "content", "")
            "- Trigger Phrase: \"#{title}\" -> Replacement Content: \"#{content}\""
          end)
          |> Enum.join("\n")
        else
          "No snippets available."
        end

      # DEBUG LOGGING FOR PROMPT CONTEXT
      Logger.info("""
      Generated Bedrock Context:
      --- Correction Rules ---
      #{dictionary_rules_context}
      --- Vocabulary ---
      #{vocabulary_context}
      --- Snippets ---
      #{snippets_context}
      ------------------------
      """)

      system_prompt = """
      #{@system_instructions}

      ### DATA CONTEXT
      You are provided with user-specific data to help with the correction.

      #### 1. DICTIONARY CORRECTION RULES (Format: Incorrect -> Correct)
      #{dictionary_rules_context}

      #### 2. VOCABULARY / ENTITIES (Format: Term)
      #{vocabulary_context}

      #### 3. SNIPPET TRIGGERS (Format: Trigger -> Content)
      #{snippets_context}

      ### INSTRUCTIONS

      **PRIORITY 1: SMART REPLACEMENTS (Aggressive Fuzzy Matching)**
      - Scan the input text for phrases that sound like or are similar to the Dictionary Rules, Vocabulary, or Snippet Triggers.
      - **PHONETIC MATCHING IS CRITICAL**. Users may speak triggers imperfectly (e.g., "mai email" sounds like "my email").
      - **Vocabulary Logic**: If a word in the text sounds like a term in the 'VOCABULARY' list, replace it with the exact spelling from the list (e.g., input "Victor" -> match 'Victor' from Vocabulary).
      - **Exception to Translation Rule**: If a phrase matches a Snippet Trigger or Dictionary Rule phonetically (even if it sounds like a different language), APPLY THE REPLACEMENT.
      - **Examples**:
         - Input: "write to mai email" | Trigger: "my email" -> Content: "john@example.com" | Action: Output "write to john@example.com" (Phonetic match 'mai' -> 'my').
         - Input: "park lig" | Dictionary "Park League" -> "ParkLake" | Action: Output "ParkLake".
         - Input: "vecter" | Vocabulary: "Victor" | Action: Output "Victor".

      **PRIORITY 2: FORMATTING REQUESTS**
      - If the user explicitly asks to "format", "organize thoughts", "structure", "make a list", "put in bullet points" (in ANY language):
        - Output the content as a bulleted list.
        - Preserve introductory sentences without the '-' line.
        - Do NOT output the formatting request phrase itself.

      **PRIORITY 3: LANGUAGE PRESERVATION**
      - **General Rule**: Keep the exact language of each word as spoken.
      - **Exception**: If a fuzzy match is found in Priority 1, that matching rule takes precedence over language preservation.
      - If the input is code-switched (mixed languages), the output MUST be code-switched.

      **PRIORITY 4: STYLE**
      - Apply these style guidelines: #{style_guidelines}

      Output ONLY the corrected text. Do NOT include 'Output:' or any other label. Do NOT provide explanations.
      """

      user_message = """
      Input text: #{text}
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
          Logger.info("Received correction from Bedrock: '#{content}'")
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

          Logger.info("Received correction from Bedrock (via body): '#{content}'")
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
