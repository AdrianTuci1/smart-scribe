defmodule VoiceScribeAPIServer.RouterTest do
  use VoiceScribeAPIServer.ConnCase

  # Test with authentication disabled
  describe "routes with SKIP_AUTH=true" do
    setup do
      # Set the environment variable for this test
      System.put_env("SKIP_AUTH", "true")

      on_exit(fn ->
        # Clean up the environment variable after test
        System.delete_env("SKIP_AUTH")
      end)

      %{conn: build_conn()}
    end

    # Authentication routes (no auth required)
    test "POST /api/v1/auth/validate", %{conn: conn} do
      conn = put_req_header(conn, "authorization", "Bearer invalid.jwt.token")
        |> post("/api/v1/auth/validate", %{"token" => "test"})

      # Should return error because we don't have actual token validation logic
      # but should not be unauthorized
      assert json_response(conn, 400)
    end

    test "POST /api/v1/auth/refresh", %{conn: conn} do
      conn = post(conn, "/api/v1/auth/refresh", %{"refresh_token" => "test"})

      # Should return error but not unauthorized
      assert json_response(conn, 400)
    end

    test "POST /api/v1/auth/logout", %{conn: conn} do
      conn = post(conn, "/api/v1/auth/logout", %{})

      # Should return error but not unauthorized
      assert json_response(conn, 400)
    end

    # Notes endpoints
    test "GET /api/v1/notes", %{conn: conn} do
      conn = get(conn, "/api/v1/notes")

      # Should return 200 with empty list or error response, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "POST /api/v1/notes", %{conn: conn} do
      conn = post(conn, "/api/v1/notes", %{"title" => "Test", "content" => "Test content"})

      # Should return 201 or 400, but not unauthorized
      assert check_response_status(conn, 201) || check_response_status(conn, 400)
    end

    test "DELETE /api/v1/notes/1", %{conn: conn} do
      conn = delete(conn, "/api/v1/notes/1")

      # Should return 200, 404, or 400, but not unauthorized
      assert response(conn, 200) || response(conn, 404) || response(conn, 400)
    end

    # Config endpoints
    test "GET /api/v1/config/snippets", %{conn: conn} do
      conn = get(conn, "/api/v1/config/snippets")

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "POST /api/v1/config/snippets", %{conn: conn} do
      conn = post(conn, "/api/v1/config/snippets", %{"snippets" => []})

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "GET /api/v1/config/dictionary", %{conn: conn} do
      conn = get(conn, "/api/v1/config/dictionary")

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "PUT /api/v1/config/dictionary", %{conn: conn} do
      conn = put(conn, "/api/v1/config/dictionary", %{"dictionary" => []})

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "POST /api/v1/config/dictionary/save", %{conn: conn} do
      conn = post(conn, "/api/v1/config/dictionary/save", %{"dictionary" => []})

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "POST /api/v1/config/style_preferences/save", %{conn: conn} do
      conn = post(conn, "/api/v1/config/style_preferences/save", %{"preferences" => %{}})

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "POST /api/v1/config/snippets/save", %{conn: conn} do
      conn = post(conn, "/api/v1/config/snippets/save", %{"snippets" => []})

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "GET /api/v1/config/style_preferences", %{conn: conn} do
      conn = get(conn, "/api/v1/config/style_preferences")

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    # Transcription endpoints
    test "POST /api/v1/transcribe/start", %{conn: conn} do
      conn = post(conn, "/api/v1/transcribe/start", %{})

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "POST /api/v1/transcribe/chunk", %{conn: conn} do
      conn = post(conn, "/api/v1/transcribe/chunk", %{"data" => "test", "session_id" => "test"})

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "POST /api/v1/transcribe/finish", %{conn: conn} do
      conn = post(conn, "/api/v1/transcribe/finish", %{"session_id" => "test"})

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "GET /api/v1/transcribe/status", %{conn: conn} do
      conn = get(conn, "/api/v1/transcribe/status")

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    # Transcript endpoints
    test "GET /api/v1/transcripts", %{conn: conn} do
      conn = get(conn, "/api/v1/transcripts")

      # Should return 200 or 400, but not unauthorized
      assert check_response_status(conn, 200) || check_response_status(conn, 400)
    end

    test "GET /api/v1/transcripts/1", %{conn: conn} do
      conn = get(conn, "/api/v1/transcripts/1")

      # Should return 200, 404, or 400, but not unauthorized
      assert response(conn, 200) || response(conn, 404) || response(conn, 400)
    end

    test "POST /api/v1/transcripts", %{conn: conn} do
      conn = post(conn, "/api/v1/transcripts", %{"title" => "Test", "content" => "Test content"})

      # Should return 201 or 400, but not unauthorized
      assert check_response_status(conn, 201) || check_response_status(conn, 400)
    end

    test "PUT /api/v1/transcripts/1", %{conn: conn} do
      conn = put(conn, "/api/v1/transcripts/1", %{"title" => "Updated", "content" => "Updated content"})

      # Should return 200, 404, or 400, but not unauthorized
      assert response(conn, 200) || response(conn, 404) || response(conn, 400)
    end

    test "DELETE /api/v1/transcripts/1", %{conn: conn} do
      conn = delete(conn, "/api/v1/transcripts/1")

      # Should return 200, 404, or 400, but not unauthorized
      assert response(conn, 200) || response(conn, 404) || response(conn, 400)
    end

    test "POST /api/v1/transcripts/1/retry", %{conn: conn} do
      conn = post(conn, "/api/v1/transcripts/1/retry")

      # Should return 200, 404, or 400, but not unauthorized
      assert response(conn, 200) || response(conn, 404) || response(conn, 400)
    end

    test "GET /api/v1/transcripts/1/audio", %{conn: conn} do
      conn = get(conn, "/api/v1/transcripts/1/audio")

      # Should return 200, 404, or 400, but not unauthorized
      assert response(conn, 200) || response(conn, 404) || response(conn, 400)
    end
  end

  # Test with authentication enabled (default)
  describe "routes with SKIP_AUTH=false (default)" do
    test "GET /api/v1/notes requires authentication", %{conn: conn} do
      conn = get(conn, "/api/v1/notes")

      # Should return 401 unauthorized
      assert response(conn, 401)
    end

    test "GET /api/v1/transcripts requires authentication", %{conn: conn} do
      conn = get(conn, "/api/v1/transcripts")

      # Should return 401 unauthorized
      assert response(conn, 401)
    end
  end

  # Helper function to get response status code
  defp check_response_status(conn, expected_status) do
    if conn.status == expected_status do
      conn.status
    else
      nil
    end
  end
end
