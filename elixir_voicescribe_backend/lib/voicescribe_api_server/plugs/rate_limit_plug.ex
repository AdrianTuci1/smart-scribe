defmodule VoiceScribeAPIServer.RateLimitPlug do
  @moduledoc """
  Plug for rate limiting API requests based on user ID
  """

  import Plug.Conn
  require Logger

  # Import Jason for JSON encoding
  require Jason

  # In-memory storage for rate limiting with TTL
  # In production, this should be replaced with Redis or similar
  @ets_table :rate_limits

  def init(opts) do
    # Initialize ETS table if not exists
    # Initialize ETS table if not exists
    if :ets.whereis(@ets_table) == :undefined do
      try do
        :ets.new(@ets_table, [:set, :public, :named_table])
      rescue
        _ -> :ok
      end
    end

    # Configure rate limit from options or use default
    # requests per minute
    Keyword.get(opts, :limit, 10)
  end

  def call(conn, limit) do
    # Get user ID from connection (set by auth plug)
    user_id = conn.assigns[:current_user]

    # Skip rate limiting for health checks or if no user ID
    if is_nil(user_id) or health_check_path?(conn.request_path) do
      conn
    else
      check_rate_limit(conn, user_id, limit)
    end
  end

  defp check_rate_limit(conn, user_id, limit) do
    current_time = System.system_time(:second)
    # 1 minute window
    minute_window = 60

    # Ensure ETS table exists
    if :ets.whereis(@ets_table) == :undefined do
      try do
        :ets.new(@ets_table, [:set, :public, :named_table])
      rescue
        _ -> :ok
      end
    end

    # Get or create user rate limit entry
    user_key = "user:#{user_id}"

    case :ets.lookup(@ets_table, user_key) do
      [] ->
        # First request in window
        :ets.insert(@ets_table, {user_key, %{count: 1, window_start: current_time}})

        conn
        |> put_resp_header("x-ratelimit-limit", integer_to_string(limit))
        |> put_resp_header("x-ratelimit-remaining", integer_to_string(limit - 1))
        |> put_resp_header("x-ratelimit-reset", integer_to_string(current_time + minute_window))

      [{^user_key, data}] ->
        window_start = Map.get(data, :window_start, current_time)
        count = Map.get(data, :count, 0)

        cond do
          current_time - window_start >= minute_window ->
            # Window expired, reset counter
            :ets.insert(@ets_table, {user_key, %{count: 1, window_start: current_time}})

            conn
            |> put_resp_header("x-ratelimit-limit", integer_to_string(limit))
            |> put_resp_header("x-ratelimit-remaining", integer_to_string(limit - 1))
            |> put_resp_header(
              "x-ratelimit-reset",
              integer_to_string(current_time + minute_window)
            )

          count >= limit ->
            # Rate limit exceeded
            Logger.warning("Rate limit exceeded for user #{user_id}")

            conn
            |> put_status(:too_many_requests)
            |> put_resp_header("retry-after", "60")
            |> put_resp_content_type("application/json")
            |> resp(
              :too_many_requests,
              Jason.encode!(%{
                error: "Rate limit exceeded",
                message: "Too many requests. Please try again later.",
                retry_after: 60
              })
            )
            |> halt()

          true ->
            # Increment counter
            new_count = count + 1
            :ets.insert(@ets_table, {user_key, %{count: new_count, window_start: window_start}})

            conn
            |> put_resp_header("x-ratelimit-limit", integer_to_string(limit))
            |> put_resp_header("x-ratelimit-remaining", integer_to_string(limit - new_count))
            |> put_resp_header(
              "x-ratelimit-reset",
              integer_to_string(window_start + minute_window)
            )
        end
    end
  end

  defp health_check_path?(path) do
    path in ["/health", "/api/v1/health", "/status"]
  end

  defp integer_to_string(integer) when is_integer(integer) do
    Integer.to_string(integer)
  end
end
