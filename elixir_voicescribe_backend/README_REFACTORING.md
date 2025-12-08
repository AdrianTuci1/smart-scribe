# Refactoring: ElixirWhisperFlowBackend → VoiceScribeAPI

## Modificări efectuate

### 1. Redenumirea modulelor
- `elixir_whisper_flow_backend` → `voicescribe_api`
- `elixir_whisper_flow_backend_web` → `voicescribe_api_server`

### 2. Eliminarea componentelor web nefolosite
- Eliminate LiveView și componente HTML
- Eliminate template-uri și pagini web
- Eliminate dashboard de dezvoltare
- Păstrat doar API endpoints

### 3. Eliminarea WebSocket-ului și implementarea transcrierii batch
- Eliminate canalele WebSocket pentru transcriere în timp real
- Implementat sistem de transcriere batch:
  1. Clientul Swift trimite chunk-uri audio
  2. Serverul "lipește" chunk-urile pentru a forma fișierul audio complet
  3. Trimite fișierul către AWS Transcribe
  4. Primește textul transcris
  5. Procesează textul cu Bedrock

### 4. Restructurarea router-ului
- Eliminate rutele browser
- Păstrat doar rutele API (`/api/v1/*`)
- Adăugat rute pentru transcriere batch

### 5. Actualizarea configurației
- Actualizat toate fișierele de configurare (config.exs, dev.exs, prod.exs, runtime.exs, test.exs)
- Eliminat dependențe nefolosite (phoenix_html, phoenix_live_view, phoenix_live_dashboard)
- Actualizat mix.exs pentru a reflecta noile nume

## Structura actuală

```
lib/
├── voicescribe_api/                    # Logica de business
│   ├── application.ex                 # Aplicația OTP
│   ├── ai/
│   │   ├── bedrock_client.ex          # Client pentru AWS Bedrock
│   │   └── transcribe_client.ex      # Client pentru AWS Transcribe
│   ├── cognito/
│   │   └── auth.ex                   # Autentificare Cognito
│   ├── repo/
│   │   └── dynamo_db_repo.ex         # Repository DynamoDB
│   └── transcription/
│       ├── transcribe_gen_server.ex  # Server pentru transcriere (vechi)
│       └── transcribe_session_manager.ex # Manager pentru sesiuni batch
└── voicescribe_api_server/            # Server API
    ├── endpoint.ex                    # Endpoint Phoenix
    ├── router.ex                     # Router API
    ├── controllers/                   # Controllere API
    │   ├── auth_controller.ex         # Autentificare
    │   ├── config_controller.ex       # Configurări
    │   ├── notes_controller.ex        # Note
    │   ├── transcribe_controller.ex   # Transcriere batch
    │   └── error_json.ex             # Erori JSON
    └── plugs/
        └── auth_plug.ex              # Plug pentru autentificare
```

## API Endpoints

### Autentificare
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/signup` - Înregistrare
- `POST /api/v1/auth/confirm` - Confirmare înregistrare
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - Logout

### Note
- `GET /api/v1/notes` - Listare note
- `POST /api/v1/notes` - Creare notă
- `DELETE /api/v1/notes/:id` - Ștergere notă

### Configurări
- `GET /api/v1/config/snippets` - Get snippets
- `POST /api/v1/config/snippets` - Save snippets
- `GET /api/v1/config/dictionary` - Get dictionary
- `PUT /api/v1/config/dictionary` - Save dictionary
- `POST /api/v1/config/dictionary/save` - Save dictionary
- `POST /api/v1/config/style_preferences/save` - Save style preferences
- `POST /api/v1/config/snippets/save` - Save snippets
- `GET /api/v1/config/style_preferences` - Get style preferences

### Transcriere Batch
- `POST /api/v1/transcribe/start` - Începe o sesiune de transcriere
  - Request body: `{"user_id": "user123"}`
  - Response: `{"status": "ok", "session_id": "abc123"}`
  
- `POST /api/v1/transcribe/chunk` - Trimite un chunk de audio
  - Request body: `{"user_id": "user123", "chunk": "base64_encoded_audio_data"}`
  - Response: `{"status": "ok", "message": "Chunk received"}`
  
- `POST /api/v1/transcribe/finish` - Finalizează sesiunea și începe transcrierea
  - Request body: `{"user_id": "user123"}`
  - Response: `{"status": "ok", "message": "Processing transcription"}`
  
- `GET /api/v1/transcribe/status` - Verifică statusul sesiunii
  - Request body: `{"user_id": "user123"}`
  - Response: 
    ```json
    {
      "status": "ok",
      "session": {
        "session_id": "abc123",
        "status": "completed",
        "created_at": "2023-01-01T12:00:00Z",
        "completed_at": "2023-01-01T12:05:00Z",
        "result": "Textul transcris și procesat",
        "error": null
      }
    }
    ```

## Flux de transcriere batch

1. **Începere sesiune**: Clientul Swift trimite `POST /api/v1/transcribe/start` cu user_id
2. **Trimitere chunk-uri**: Clientul trimite chunk-uri audio prin `POST /api/v1/transcribe/chunk`
3. **Finalizare**: Clientul trimite `POST /api/v1/transcribe/finish` pentru a semnala finalizarea
4. **Procesare**: Serverul combină chunk-urile, trimite la AWS Transcribe, primește textul
5. **Procesare cu Bedrock**: Textul este procesat cu AWS Bedrock
6. **Verificare status**: Clientul poate verifica statusul prin `GET /api/v1/transcribe/status`

## Cum se compilează și pornește

```bash
# Instalare dependențe
mix deps.get

# Compilare
mix compile

# Pornire server
mix phx.server
```

## Notițe

Serverul acum servește doar ca API backend pentru aplicația Swift nativă. Nu există componente web vizibile, doar endpoint-uri API. Transcrierea audio se face în mod batch, nu în timp real prin WebSocket.
