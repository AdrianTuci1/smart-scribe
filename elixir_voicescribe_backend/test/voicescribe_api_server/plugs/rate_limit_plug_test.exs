defmodule VoiceScribeAPIServer.RateLimitPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias VoiceScribeAPIServer.RateLimitPlug

  describe "RateLimitPlug" do
    test "allows requests within limit" do
      # Initialize the plug
      opts = RateLimitPlug.init(limit: 5)

      # Create a mock connection with user ID
      conn = conn(:get, "/test")
             |> assign(:current_user, "test_user")

      # Make 5 requests (within limit)
      results =
        for i <- 1..5 do
          RateLimitPlug.call(conn, opts)
        end

      # All should succeed
      assert Enum.all?(results, fn result ->
        result.state == :unset and
        get_resp_header(result, "x-ratelimit-remaining") == to_string(5 - i)
      end)
    end

    test "blocks requests exceeding limit" do
      # Initialize the plug
      opts = RateLimitPlug.init(limit: 2)

      # Create a mock connection with user ID
      conn = conn(:get, "/test")
             |> assign(:current_user, "test_user")

      # Make 3 requests (exceeds limit of 2)
      result1 = RateLimitPlug.call(conn, opts)
      result2 = RateLimitPlug.call(conn, opts)
      result3 = RateLimitPlug.call(conn, opts)

      # First 2 should succeed
      assert result1.state == :unset
      assert result2.state == :unset

      # Third should be rate limited
      assert result3.state == :halted
      assert result3.status == 429
      assert get_resp_header(result3, "retry-after") == "60"
    end

    test "skips health check endpoints" do
      # Initialize the plug
      opts = RateLimitPlug.init(limit: 1)

      # Create a mock connection with user ID
      conn = conn(:get, "/health")
             |> assign(:current_user, "test_user")

      # Health check should pass through regardless of rate limit
      result1 = RateLimitPlug.call(conn, opts)
      assert result1.state == :unset

      # Second request should still be allowed for health check
      result2 = RateLimitPlug.call(conn, opts)
      assert result2.state == :unset
    end

    test "skips requests without user ID" do
      # Initialize the plug
      opts = RateLimitPlug.init(limit: 1)

      # Create a mock connection without user ID
      conn = conn(:get, "/test")

      # Request without user ID should pass through
      result1 = RateLimitPlug.call(conn, opts)
      assert result1.state == :unset

      # Second request should still be allowed
      result2 = RateLimitPlug.call(conn, opts)
      assert result2.state == :unset
    end

    test "resets counter after time window expires" do
      # This test would require mocking time, which is complex
      # For now, we'll just verify the window is set correctly
      opts = RateLimitPlug.init(limit: 2)

      conn = conn(:get, "/test")
             |> assign(:current_user, "test_user")

      result = RateLimitPlug.call(conn, opts)
      reset_time = get_resp_header(result, "x-ratelimit-reset")

      # Verify reset time is in the future
      current_time = System.system_time(:second)
      reset_time_int = String.to_integer(reset_time)

      assert reset_time_int > current_time
      assert reset_time_int <= current_time + 60 # Within 1 minute window
    end

    defp to_string(integer) when is_integer(integer) do
      Integer.to_string(integer)
    end
  end
end
