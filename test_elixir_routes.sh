#!/bin/bash

# Script to run Elixir tests for all routes with SKIP_AUTH=true

echo "=== Running Elixir tests for VoiceScribe API routes ==="

# Set the working directory to the backend
cd /Users/adriantucicovenco/Proiecte/smartscribe/elixir_voicescribe_backend

# Set environment variable
export SKIP_AUTH=true

echo "Running tests with SKIP_AUTH=true..."

# Run the tests
mix test test/voicescribe_api_server/router_test.exs

echo "=== Tests completed ==="