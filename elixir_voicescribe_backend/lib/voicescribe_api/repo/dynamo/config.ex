defmodule VoiceScribeAPI.Repo.Dynamo.Config do
  @moduledoc """
  DynamoDB operations for User Configuration (Settings, Dictionary, Usage, etc.)
  """
  alias ExAws.Dynamo
  import VoiceScribeAPI.Repo.Dynamo.Utils

  @config_table "UserConfigsTable"

  # Configs
  def get_config(user_id, config_type) do
    case Dynamo.get_item(@config_table, %{userId: user_id, configType: config_type})
         |> ExAws.request() do
      {:ok, result} ->
        case result do
          %{"Item" => item} when item != nil ->
            decode_item(item)

          _ ->
            %{}
        end

      {:error, reason} ->
        # Propagate error instead of masking it as empty
        {:error, reason}
    end
  end

  def put_config(user_id, config_type, data) do
    item = Map.merge(data, %{"userId" => user_id, "configType" => config_type})
    Dynamo.put_item(@config_table, item) |> ExAws.request()
  end

  # Dictionary entries
  def get_dictionary_entries(user_id) do
    case get_config(user_id, "dictionary") do
      empty_map when empty_map == %{} ->
        []

      config ->
        entries = Map.get(config, "entries", [])
        # Convert entries to a list of dictionaries if needed
        case entries do
          nil -> []
          list when is_list(list) -> list
          _ -> []
        end
    end
  end

  def put_dictionary_entry(user_id, entry) do
    # Get existing dictionary
    case get_dictionary_entries(user_id) do
      entries ->
        new_entry = %{
          incorrectWord: entry.incorrectWord,
          correctWord: entry.correctWord,
          createdAt: DateTime.utc_now()
        }

        # Update entries with new entry
        updated_entries = [new_entry | entries]

        # Save back to DynamoDB
        data = %{
          "userId" => user_id,
          "configType" => "dictionary",
          "entries" => updated_entries
        }

        item = Map.merge(data, %{"configType" => "dictionary", "userId" => user_id})
        Dynamo.put_item(@config_table, item) |> ExAws.request()
    end
  end

  def delete_dictionary_entry(user_id, incorrect_word) do
    case get_dictionary_entries(user_id) do
      entries ->
        # Filter out the entry to delete
        updated_entries =
          Enum.filter(entries, fn entry ->
            entry.incorrectWord != incorrect_word
          end)

        # Save back to DynamoDB
        data = %{
          "userId" => user_id,
          "configType" => "dictionary",
          "entries" => updated_entries
        }

        item = Map.merge(data, %{"configType" => "dictionary", "userId" => user_id})
        Dynamo.put_item(@config_table, item) |> ExAws.request()
    end
  end

  # Usage / Free Tier
  def get_usage(user_id) do
    get_config(user_id, "usage")
  end

  def update_usage(user_id, word_count) do
    current_time = DateTime.utc_now()

    current_month_start =
      Date.beginning_of_month(current_time)
      |> DateTime.new!(~T[00:00:00])
      |> DateTime.to_iso8601()

    case get_usage(user_id) do
      {:error, reason} ->
        # If DB is down, we should probably fail or log, but definitely NOT create a new usage record from scratch
        # which would reset their usage count.
        {:error, reason}

      usage when usage == %{} ->
        # Initialize usage
        new_usage = %{
          "wordCount" => word_count,
          "periodStart" => current_month_start
        }

        put_config(user_id, "usage", new_usage)

      %{"periodStart" => period_start} = usage ->
        # Check if we need to reset (new month)
        saved_start =
          case DateTime.from_iso8601(period_start) do
            {:ok, dt, _} -> dt
            # Fallback
            _ -> DateTime.utc_now()
          end

        # Compare months (simplistic approach: if saved month < current month)
        if saved_start.month != current_time.month or saved_start.year != current_time.year do
          # Reset
          new_usage = %{
            "wordCount" => word_count,
            "periodStart" => current_month_start
          }

          put_config(user_id, "usage", new_usage)
        else
          # Increment
          # DynamoDB may store wordCount as string, so convert to integer
          current_count =
            case Map.get(usage, "wordCount", 0) do
              count when is_integer(count) -> count
              count when is_binary(count) -> String.to_integer(count)
              _ -> 0
            end

          new_usage = Map.put(usage, "wordCount", current_count + word_count)
          put_config(user_id, "usage", new_usage)
        end

      _ ->
        # Fallback for weird state (but not error state)
        new_usage = %{
          "wordCount" => word_count,
          "periodStart" => current_month_start
        }

        put_config(user_id, "usage", new_usage)
    end
  end

  # Subscription Config
  def get_subscription_config(user_id) do
    get_config(user_id, "subscription")
  end

  def update_subscription_config(user_id, data) do
    put_config(user_id, "subscription", data)
  end

  # User Lookup (Scan)
  def get_user_by_email(email) do
    # Scan for configType = 'settings' and email inside the map
    # Note: Scanning is expensive. Add GSI in production.
    # We need to scan and filter manually or use FilterExpression if mapped
    # Since 'data' is a map flattened into the item (because of Map.merge in put_config),
    # we can check for attribute 'email'.

    Dynamo.scan(@config_table,
      filter_expression: "email = :email AND configType = :ctype",
      expression_attribute_values: [email: email, ctype: "settings"]
    )
    |> ExAws.request()
    |> case do
      {:ok, %{"Items" => [item | _]}} ->
        decoded = decode_item(item)
        {:ok, decoded["userId"]}

      {:ok, %{"Items" => []}} ->
        {:error, :not_found}

      _ ->
        {:error, :not_found}
    end
  end
end
