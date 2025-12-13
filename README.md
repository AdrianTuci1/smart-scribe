# VoiceScribe - AI-Powered Real-Time Transcription

## System Architecture

The VoiceScribe system is built on a high-performance, event-driven architecture designed for low-latency real-time transcription and intelligent post-processing. It leverages the power of Elixir for concurrency and AWS for scalable AI services.

### Data Flow Overview

```mermaid
graph LR
    User[User (Swift App)] -- WebSocket (Audio Stream) --> Backend[Elixir Backend]
    Backend -- HTTP/2 Stream --> Transcribe[AWS Transcribe]
    Transcribe -- Partial/Final Results --> Backend
    Backend -- JSON --> Bedrock[AWS Bedrock (Claude)]
    Backend -- WebSocket (Events) --> User
    Bedrock -- Enhanced Text --> Backend
    Backend -- Save --> DynamoDB[(DynamoDB)]
```

### Component Breakdown

1.  **Swift Client (macOS)**
    *   **Role**: Frontend & Audio Capture.
    *   **Function**: Captures high-fidelity audio input from the microphone and streams it in real-time binary chunks via WebSocket to the backend. It handles local state, the floating UI overlay, and global hotkeys for seamless system-wide integration.

2.  **Elixir Backend (Phoenix)**
    *   **Role**: Orchestrator & WebSocket Server.
    *   **Function**: Serves as the central hub. It accepts the WebSocket stream from the client, manages the session state using GenServers, and securely signs and proxies the audio stream to AWS Transcribe. It also orchestrates the handoff to Bedrock for post-processing.
    *   **Key Tech**: Phoenix Framework, WebSockex, GenServer.

3.  **AWS Transcribe (Streaming)**
    *   **Role**: Speech-to-Text Engine.
    *   **Function**: Receives the PCM audio stream from Elixir and performs real-time speech-to-text conversion. It pushes partial (unstable) and final (stable) transcription events back to the backend instantly.

4.  **AWS Bedrock (Claude)**
    *   **Role**: Intelligent Post-Processing.
    *   **Function**: Once a transcription segment is finalized, the raw text is sent to a Large Language Model (Claude via Bedrock). The model corrects grammar, applies specific user-defined style guides / dictionaries, and formats the text (e.g., medical or legal terminology) before returning it.

5.  **DynamoDB**
    *   **Role**: Persistence Layer.
    *   **Function**: Stores user configurations, custom dictionaries, snippets, and the final enriched transcripts for persistence and cross-device synchronization.

## Application Utility

VoiceScribe is designed for professionals (doctors, lawyers, developers) who need:
*   **Instant Dictation**: Type with your voice in any application using the floating overlay, replacing standard keyboard input.
*   **Context-Aware Correction**: Unlike standard dictation, VoiceScribe uses LLMs to "understand" the context, fixing homophones, punctuation, and grammar based on the specific domain (e.g., converting "thyroidectomy" correctly in a medical context).
*   **Customizable Style**: Users can define specific rules (e.g., "always format dates as YYYY-MM-DD" or "use concise bullet points").
*   **Seamless Integration**: Works system-wide on macOS without requiring plugins for individual target apps.

## Performance & Scalability

### Throughput & Concurrency
*   **Elixir/BEAM VM**: The backend is built on the Erlang VM, which is famous for its ability to handle massive concurrency. A single backend node can easily handle thousands of concurrent real-time audio streams with minimal CPU and memory overhead.
*   **Event-Driven**: The entire pipeline is non-blocking. Audio chunks flow through the system asynchronously, ensuring that one heavy processing task does not block other users.

### Scalability
*   **Stateless Processing**: While the WebSocket connection is stateful for the duration of the session, the architecture allows for easy horizontal scaling. Audio processing is offloaded to AWS managed services, keeping the backend layer lightweight.
*   **Serverless Database**: DynamoDB provides single-digit millisecond latency at any scale, capable of handling millions of requests per second, ensuring the app remains snappy regardless of user load.

### Expected Response Time
*   **Real-Time Transcription**: **< 500ms** latency. Users see words appear on their screen almost instantly as they speak (via partial results).
*   **AI Post-Processing**: **~1-2 seconds**. Once the user pauses or finishes a sentence, the "final" correction from Bedrock replaces the raw text. This depends on the model used.

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

### 4. Running Frontend (Optional / Demo)
```bash
cd frontend
npm install
npm run dev
```

## API Endpoints
- `POST /api/v1/notes`: Create/Sync notes.
- `WebSocket /socket`: Main entry point for `transcription:USER_ID` channel.
