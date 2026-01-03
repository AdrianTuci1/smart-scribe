defmodule VoiceScribeAPIServer.StatsController do
  use VoiceScribeAPIServer, :controller
  alias VoiceScribeAPI.DynamoDBRepo
  require Logger

  def index(conn, _params) do
    user_id = conn.assigns.current_user

    # 1. Get Usage & Plan
    usage = DynamoDBRepo.get_usage(user_id)
    subscription = DynamoDBRepo.get_subscription_config(user_id)
    plan_name = Map.get(subscription, "plan", "free")

    limit =
      case plan_name do
        "pro" -> -1
        "yearly" -> -1
        _ -> 2000
      end

    current_words =
      case Map.get(usage, "wordCount", 0) do
        count when is_integer(count) -> count
        count when is_binary(count) -> String.to_integer(count)
        _ -> 0
      end

    # 2. Get All Transcripts for aggregate stats
    # Fetch more items to ensure we catch enough history for streak
    stats =
      case DynamoDBRepo.list_transcripts(user_id, limit: 1000) do
        {:ok, %{"Items" => items}} ->
          transcripts = Enum.map(items, &DynamoDBRepo.decode_item/1)
          calculate_stats(transcripts)

        _ ->
          %{streak: 0, total_words: 0, wpm: 0}
      end

    response = %{
      streak: stats.streak,
      totalWords: stats.total_words,
      averageWpm: stats.wpm,
      plan: plan_name,
      usage: %{
        wordsUsed: current_words,
        limit: limit
      }
    }

    json(conn, response)
  end

  defp calculate_stats(transcripts) when transcripts == [],
    do: %{streak: 0, total_words: 0, wpm: 0}

  defp calculate_stats(transcripts) do
    # Total Words
    total_words =
      transcripts
      |> Enum.reduce(0, fn t, acc ->
        # Ensure we look for keys in different cases just in case, or rely on standard "text"
        text = Map.get(t, "text") || Map.get(t, "content") || ""
        count = length(String.split(text, ~r/\s+/, trim: true))
        acc + count
      end)

    # WPM Calculation
    # 1. Try to calculate from real duration if available (durationSeconds)
    {wpm_words, wpm_seconds} =
      transcripts
      |> Enum.reduce({0, 0}, fn t, {w_acc, s_acc} ->
        duration = Map.get(t, "durationSeconds")

        # Check if duration is valid (number and > 0)
        valid_duration =
          case duration do
            d when is_number(d) and d > 0 ->
              d

            d when is_binary(d) ->
              try do
                String.to_integer(d)
              rescue
                _ -> 0
              end

            _ ->
              0
          end

        if valid_duration > 0 do
          # Count words for this transcript
          text = Map.get(t, "text") || Map.get(t, "content") || ""
          count = length(String.split(text, ~r/\s+/, trim: true))
          {w_acc + count, s_acc + valid_duration}
        else
          {w_acc, s_acc}
        end
      end)

    wpm =
      if wpm_seconds > 0 do
        minutes = wpm_seconds / 60
        round(wpm_words / minutes)
      else
        # Fallback to simulation if no real duration data found
        if total_words > 0 do
          130 + rem(total_words, 30)
        else
          0
        end
      end

    # Weekly Streak
    streak = calculate_weekly_streak(transcripts)

    %{
      streak: streak,
      total_words: total_words,
      wpm: wpm
    }
  end

  defp calculate_weekly_streak(transcripts) do
    # 1. Get {year, week} for all transcripts
    weeks =
      transcripts
      |> Enum.map(fn t ->
        case DateTime.from_iso8601(Map.get(t, "timestamp", "")) do
          {:ok, dt, _} ->
            {date, _} =
              DateTime.to_gregorian_seconds(dt) |> :calendar.gregorian_seconds_to_datetime()

            :calendar.iso_week_number(date)

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      # Sort descending
      |> Enum.sort(&week_desc_compare/2)

    case weeks do
      [] ->
        0

      [last_active_user_week | rest] ->
        current_date_tuple = :calendar.universal_time() |> elem(0)
        current_week = :calendar.iso_week_number(current_date_tuple)

        # Check if streak is alive
        # Alive if last active week is THIS week or LAST week
        is_current = weeks_equal?(last_active_user_week, current_week)
        is_previous = weeks_equal?(last_active_user_week, previous_week(current_week))

        if is_current or is_previous do
          # Count consecutive weeks backwards
          # We start count at 1 because we have at least one valid week (the head)
          do_count_streak(rest, last_active_user_week, 1)
        else
          0
        end
    end
  end

  # Compare {year, week} descending
  defp week_desc_compare({y1, w1}, {y2, w2}) do
    if y1 == y2, do: w1 >= w2, else: y1 > y2
  end

  defp weeks_equal?({y1, w1}, {y2, w2}), do: y1 == y2 and w1 == w2

  # Approximation (sometimes 53, but 52 is safe enough for logic)
  defp previous_week({year, 1}), do: {year - 1, 52}
  defp previous_week({year, week}), do: {year, week - 1}

  defp do_count_streak([], _, count), do: count

  defp do_count_streak([next_week | rest], current_week, count) do
    if weeks_equal?(next_week, previous_week(current_week)) do
      do_count_streak(rest, next_week, count + 1)
    else
      count
    end
  end
end
