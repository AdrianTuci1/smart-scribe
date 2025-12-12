#!/bin/bash

# Script to test all routes in the VoiceScribe API with SKIP_AUTH=true
# This script starts the server with SKIP_AUTH=true and tests all routes

echo "=== Testing VoiceScribe API routes with SKIP_AUTH=true ==="

# Set the working directory to the backend
cd /Users/adriantucicovenco/Proiecte/smartscribe/elixir_voicescribe_backend

# Set environment variable
export SKIP_AUTH=true

echo "Starting server with SKIP_AUTH=true..."
echo "This may take a moment to start..."

# Start the server in background
mix phx.server &
SERVER_PID=$!

# Function to cleanup when script exits
cleanup() {
    echo "Cleaning up..."
    kill $SERVER_PID 2>/dev/null
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup INT TERM EXIT

# Wait for server to start
echo "Waiting for server to start..."
sleep 10

# Test if server is running
echo "Checking if server is running..."
if curl -s http://localhost:4000/api/v1/notes > /dev/null 2>&1; then
    echo "Server is running!"
else
    echo "Failed to start server"
    exit 1
fi

# Test authentication routes
echo "=== Testing Authentication Routes ==="
echo -e "\nPOST /api/v1/auth/validate:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"token": "test_token"}' http://localhost:4000/api/v1/auth/validate

echo -e "\nPOST /api/v1/auth/refresh:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"refresh_token": "test_refresh_token"}' http://localhost:4000/api/v1/auth/refresh

echo -e "\nPOST /api/v1/auth/logout:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{}' http://localhost:4000/api/v1/auth/logout

# Test notes endpoints
echo -e "\n=== Testing Notes Endpoints ==="
echo -e "\nGET /api/v1/notes:"
curl -s -w "\nStatus: %{http_code}\n" -X GET http://localhost:4000/api/v1/notes

echo -e "\nPOST /api/v1/notes:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"title": "Test Note", "content": "This is a test note"}' http://localhost:4000/api/v1/notes

echo -e "\nDELETE /api/v1/notes/1:"
curl -s -w "\nStatus: %{http_code}\n" -X DELETE http://localhost:4000/api/v1/notes/1

# Test config endpoints - snippets
echo -e "\n=== Testing Config Endpoints - Snippets ==="
echo -e "\nGET /api/v1/config/snippets:"
curl -s -w "\nStatus: %{http_code}\n" -X GET http://localhost:4000/api/v1/config/snippets

echo -e "\nPOST /api/v1/config/snippets:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"snippets": [{"text": "test snippet", "abbreviation": "ts"}]}' http://localhost:4000/api/v1/config/snippets

echo -e "\nPOST /api/v1/config/snippets/save:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"snippets": [{"text": "test snippet", "abbreviation": "ts"}]}' http://localhost:4000/api/v1/config/snippets/save

# Test config endpoints - dictionary
echo -e "\n=== Testing Config Endpoints - Dictionary ==="
echo -e "\nGET /api/v1/config/dictionary:"
curl -s -w "\nStatus: %{http_code}\n" -X GET http://localhost:4000/api/v1/config/dictionary

echo -e "\nPUT /api/v1/config/dictionary:"
curl -s -w "\nStatus: %{http_code}\n" -X PUT -H "Content-Type: application/json" -d '{"dictionary": [{"word": "test", "replacement": "replacement"}]}' http://localhost:4000/api/v1/config/dictionary

echo -e "\nPOST /api/v1/config/dictionary/save:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"dictionary": [{"word": "test", "replacement": "replacement"}]}' http://localhost:4000/api/v1/config/dictionary/save

# Test config endpoints - style preferences
echo -e "\n=== Testing Config Endpoints - Style Preferences ==="
echo -e "\nGET /api/v1/config/style_preferences:"
curl -s -w "\nStatus: %{http_code}\n" -X GET http://localhost:4000/api/v1/config/style_preferences

echo -e "\nPOST /api/v1/config/style_preferences/save:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"preferences": {"punctuation": true, "capitalization": true}}' http://localhost:4000/api/v1/config/style_preferences/save

# Test transcription endpoints
echo -e "\n=== Testing Transcription Endpoints ==="
echo -e "\nPOST /api/v1/transcribe/start:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{}' http://localhost:4000/api/v1/transcribe/start

echo -e "\nPOST /api/v1/transcribe/chunk:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"session_id": "test_session", "data": "base64_encoded_audio_chunk"}' http://localhost:4000/api/v1/transcribe/chunk

echo -e "\nPOST /api/v1/transcribe/finish:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"session_id": "test_session"}' http://localhost:4000/api/v1/transcribe/finish

echo -e "\nGET /api/v1/transcribe/status:"
curl -s -w "\nStatus: %{http_code}\n" -X GET http://localhost:4000/api/v1/transcribe/status

# Test transcript endpoints
echo -e "\n=== Testing Transcript Endpoints ==="
echo -e "\nGET /api/v1/transcripts:"
curl -s -w "\nStatus: %{http_code}\n" -X GET http://localhost:4000/api/v1/transcripts

echo -e "\nGET /api/v1/transcripts/1:"
curl -s -w "\nStatus: %{http_code}\n" -X GET http://localhost:4000/api/v1/transcripts/1

echo -e "\nPOST /api/v1/transcripts:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"title": "Test Transcript", "content": "This is a test transcript"}' http://localhost:4000/api/v1/transcripts

echo -e "\nPUT /api/v1/transcripts/1:"
curl -s -w "\nStatus: %{http_code}\n" -X PUT -H "Content-Type: application/json" -d '{"title": "Updated Transcript", "content": "This is an updated test transcript"}' http://localhost:4000/api/v1/transcripts/1

echo -e "\nDELETE /api/v1/transcripts/1:"
curl -s -w "\nStatus: %{http_code}\n" -X DELETE http://localhost:4000/api/v1/transcripts/1

echo -e "\nPOST /api/v1/transcripts/1/retry:"
curl -s -w "\nStatus: %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{}' http://localhost:4000/api/v1/transcripts/1/retry

echo -e "\nGET /api/v1/transcripts/1/audio:"
curl -s -w "\nStatus: %{http_code}\n" -X GET http://localhost:4000/api/v1/transcripts/1/audio

echo -e "\n=== Testing completed ==="
echo "All routes have been tested with SKIP_AUTH=true"