# VoiceScribe

## Architecture
- **Backend**: Elixir/Phoenix (Dockerized) with AWS integrations (DynamoDB, Bedrock, Transcribe).
- **Frontend**: React + Vite (demonstrating WebSocket connection).

## Quick Start

### 1. Prerequisites
- Docker & Docker Desktop (Running)
- AWS Credentials configured in Environment or `~/.aws/credentials`.

### 2. AWS Setup
Follow [aws_setup.md](aws_setup.md) to provision DynamoDB, Cognito, and ECS resources.

### 3. Running Backend (Docker)
```bash
cd elixir_whisper_flow_backend
docker build -t voicescribe-backend .
docker run -p 4000:4000 \
  -e AWS_REGION=eu-central-1 \
  -e AWS_ACCESS_KEY_ID=... \
  -e AWS_SECRET_ACCESS_KEY=... \
  voicescribe-backend
```

### 4. Running Frontend
```bash
cd frontend
npm install
npm run dev
```

## API
- `POST /api/v1/notes`
- `WebSocket /socket` (Channel `transcription:USER_ID`)
