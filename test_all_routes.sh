#!/bin/bash

# Script to test all routes in the VoiceScribe API both with and without authentication

echo "=== Testing VoiceScribe API routes ==="

# Set the working directory to the backend
cd /Users/adriantucicovenco/Proiecte/smartscribe/elixir_voicescribe_backend

echo "=== Testing with SKIP_AUTH=true (Authentication disabled) ==="

# Set environment variable
export SKIP_AUTH=true

echo "Running tests with SKIP_AUTH=true..."
mix test test/voicescribe_api_server/router_test.exs --only "routes with SKIP_AUTH=true"

echo -e "\n=== Testing with SKIP_AUTH=false (Authentication enabled) ==="

# Unset environment variable
unset SKIP_AUTH

echo "Running tests with SKIP_AUTH=false..."
mix test test/voicescribe_api_server/router_test.exs --only "routes with SKIP_AUTH=false (default)"

echo -e "\n=== Running all tests ==="
mix test test/voicescribe_api_server/router_test.exs

echo -e "\n=== All tests completed ==="