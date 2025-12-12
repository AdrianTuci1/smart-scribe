# Actualizări API SmartScribe

## Noile Funcționalități Implementate

### 1. Rate Limiting
- **Descriere**: Implementare limită de 10 cereri/minut per utilizator pentru protecție împotriva abuzurilor
- **Endpoint-uri afectate**: Toate endpoint-urile protejate (`/api/v1/*`)
- **Headers adăugate**:
  - `x-ratelimit-limit`: Limita maximă de cereri
  - `x-ratelimit-remaining`: Numărul de cereri rămase
  - `x-ratelimit-reset`: Timestamp-ul resetării ferestrei
  - `retry-after`: Timpul de așteptare (secunde) când limita e depășită
- **Răspuns la depășire**:
  ```json
  {
    "error": "Rate limit exceeded",
    "message": "Too many requests. Please try again later.",
    "retry_after": 60
  }
  ```

### 2. Token Rotation Automat
- **Descriere**: Refresh automat al token-urilor cu 5 minute înainte de expirare
- **Implementare**: Scheduler în AuthService care verifică periodic expirarea
- **Beneficii**: Previne deconectările neașteptate ale utilizatorilor

### 3. Notificări Utilizator Îmbunătățite
- **Descriere**: Implementare completă a notificărilor conform cu specificațiile
- **Stări noi în FloatingWaveformChip**:
  - `processing(message: String)`: Pentru PLEASE_HOLD și SLOW_PROCESSING
  - `requestError(message: String, actionTitle: String)`: Pentru REQUEST_ISSUE
- **Mesaje implementate**:
  - PLEASE_HOLD: "Vă rugăm să așteptați. Procesarea durează mai mult decât de obicei."
  - SLOW_PROCESSING: "Ne ia mai mult timp decât de obicei. Puteți aștepta sau anula cererea."
  - REQUEST_ISSUE: "A existat o problemă cu solicitarea dumneavoastră. Vă rugăm să încercați din nou."

### 4. Compresie Gzip pentru Audio
- **Descriere**: Compresia datelor audio trimise de la client la server pentru reducerea traficului
- **Implementare client**: compresie gzip în TranscriptionService înainte de trimitere
- **Implementare server**: detectare și decomprimere automată în TranscribeSessionManager
- **Optimizare**: Reducere cu până la 70% a dimensiunii datelor audio

### 5. Optimizări DynamoDB cu Cache și Paginare
- **Descriere**: Îmbunătățiri ale interogărilor către DynamoDB
- **Cache**: Implementare cache în memorie pentru transcrierile recente (TTL: 60 secunde)
- **Paginare**: Suport pentru listări cu paginare
- **Parametri noi**:
  - `limit`: Numărul maxim de rezultate (default: 20)
  - `start_key`: Cheia de start pentru pagină următoare
- **Răspuns îmbunătățit**:
  ```json
  {
    "data": [...],
    "pagination": {
      "start_key": "...",
      "has_more": true
    }
  }
  ```

## Modificări de Structură

### Server (Elixir/Phoenix)
- **Plug nou**: `VoiceScribeAPIServer.RateLimitPlug`
- **Modificări**: 
  - `router.ex`: Adăugat pipeline `:rate_limit`
  - `transcribe_controller.ex`: Îmbunătățit logarea pentru rate limiting
  - `transcribe_session_manager.ex`: Adăugat suport pentru compresie/decompresie
  - `dynamo_db_repo.ex`: Adăugat cache și suport pentru paginare

### Client (Swift/SwiftUI)
- **Modificări**:
  - `FloatingWaveformChip.swift`: Stări și panouri noi pentru notificări
  - `TranscriptionService.swift`: Adăugat compresie gzip
  - `AuthService.swift`: Adăugat refresh automat al token-urilor

## Considerații de Securitate
- **Rate limiting**: Protecție împotriva atacurilor de tip DoS și spam
- **Token rotation**: Reducerea riscului expirării sesiunilor
- **Data validation**: Validare strictă a datelor primite

## Recomandări de Implementare
1. **Monitorizare rate limiting**: Configurare alerte pentru cazuri de depășire frecventă
2. **Redis pentru producție**: Înlocuirea cache-ului ETS cu Redis pentru scalabilitate
3. **Analiză compresie**: Monitorizarea ratei de compresie pentru a optimiza dimensiunile buffer-elor
4. **Testare de încărcare**: Testare cu volume mari de date pentru a valida performanța

## Compatibilitate
Toate modificările sunt compatibile cu:
- **Client iOS**: iOS 13+ (pentru suportul gzip nativ)
- **Server**: Elixir 1.13+ și Phoenix 1.6+
- **Baze de date**: DynamoDB cu configurare standard