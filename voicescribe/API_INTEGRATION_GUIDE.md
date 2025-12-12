# VoiceScribe API Integration Guide

This guide documents the fixed integration between the Swift iOS app and the Elixir backend.

## Overview

The VoiceScribe API follows a RESTful architecture with JSON payloads. All protected endpoints require a valid JWT token from AWS Cognito in the Authorization header.

## Authentication

The Swift app handles OAuth flow directly with Cognito and uses the obtained JWT token for API requests:

```
Authorization: Bearer <JWT_TOKEN>
```

## API Endpoints

### Base URL
```
http://localhost:4000/api/v1
```

### Configuration Endpoints

#### Get Snippets
```swift
// Swift Usage
let snippets = try await APIService.shared.fetchSnippets()
```

**Request:**
```
GET /config/snippets
Authorization: Bearer <token>
```

**Response:**
```json
{
  "data": [
    {
      "id": "UUID",
      "title": "Snippet Title",
      "content": "Snippet Content"
    }
  ]
}
```

#### Save Snippets
```swift
// Swift Usage
try await APIService.shared.saveSnippets(snippets)
```

**Request:**
```
POST /config/snippets/save
Authorization: Bearer <token>
Content-Type: application/json

{
  "snippets": [
    {
      "id": "UUID",
      "title": "Snippet Title",
      "content": "Snippet Content"
    }
  ]
}
```

**Response:**
```json
{
  "status": "ok"
}
```

#### Get Dictionary
```swift
// Swift Usage
let dictionary = try await APIService.shared.fetchDictionary()
```

**Request:**
```
GET /config/dictionary
Authorization: Bearer <token>
```

**Response:**
```json
{
  "data": [
    {
      "id": "UUID",
      "incorrect_word": "teh",
      "correct_word": "the",
      "created_at": "2023-01-01T00:00:00Z"
    }
  ]
}
```

#### Save Dictionary
```swift
// Swift Usage
try await APIService.shared.saveDictionary(dictionary)
```

**Request:**
```
POST /config/dictionary/save
Authorization: Bearer <token>
Content-Type: application/json

{
  "dictionary": {
    "entries": [
      {
        "id": "UUID",
        "incorrect_word": "teh",
        "correct_word": "the"
      }
    ]
  }
}
```

**Response:**
```json
{
  "status": "ok"
}
```

#### Get Style Preferences
```swift
// Swift Usage
let preferences = try await APIService.shared.fetchStylePreferences()
```

**Request:**
```
GET /config/style_preferences
Authorization: Bearer <token>
```

**Response:**
```json
{
  "data": {
    "context": "Personal messages",
    "style": "Casual"
  }
}
```

#### Save Style Preferences
```swift
// Swift Usage
try await APIService.shared.saveStylePreferences(preferences)
```

**Request:**
```
POST /config/style_preferences/save
Authorization: Bearer <token>
Content-Type: application/json

{
  "preferences": {
    "context": "Personal messages",
    "style": "Casual"
  }
}
```

**Response:**
```json
{
  "status": "ok"
}
```

### Notes Endpoints

#### Get Notes
```swift
// Swift Usage
let notes = try await APIService.shared.fetchNotes()
```

**Request:**
```
GET /notes
Authorization: Bearer <token>
```

**Response:**
```json
{
  "data": [
    {
      "id": "UUID",
      "content": "Note content",
      "created_at": "2023-01-01T00:00:00Z",
      "updated_at": "2023-01-01T00:00:00Z"
    }
  ]
}
```

#### Create Note
```swift
// Swift Usage
let note = try await APIService.shared.createNote(note)
```

**Request:**
```
POST /notes
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": "UUID",
  "content": "Note content",
  "created_at": "2023-01-01T00:00:00Z",
  "updated_at": "2023-01-01T00:00:00Z"
}
```

**Response:**
```json
{
  "id": "UUID",
  "content": "Note content",
  "created_at": "2023-01-01T00:00:00Z",
  "updated_at": "2023-01-01T00:00:00Z"
}
```

#### Delete Note
```swift
// Swift Usage
try await APIService.shared.deleteNote(id: noteId)
```

**Request:**
```
DELETE /notes/{id}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "ok"
}
```

### Transcription Endpoints

#### Start Transcription Session
```swift
// Swift Usage
let response = try await APIService.shared.startTranscriptionSession(userId: userId)
```

**Request:**
```
POST /transcribe/start
Authorization: Bearer <token>
Content-Type: application/json

{
  "user_id": "user-id"
}
```

**Response:**
```json
{
  "status": "ok",
  "session_id": "session-uuid"
}
```

#### Upload Transcription Chunk
```swift
// Swift Usage
try await APIService.shared.uploadTranscriptionChunk(userId: userId, chunk: chunk)
```

**Request:**
```
POST /transcribe/chunk
Authorization: Bearer <token>
Content-Type: application/json

{
  "data": "base64-encoded-audio-chunk",
  "session_id": "session-uuid"
}
```

**Response:**
```json
{
  "status": "ok",
  "message": "Chunk received"
}
```

#### Finish Transcription Session
```swift
// Swift Usage
try await APIService.shared.finishTranscriptionSession(userId: userId)
```

**Request:**
```
POST /transcribe/finish
Authorization: Bearer <token>
Content-Type: application/json

{
  "session_id": "session-uuid"
}
```

**Response:**
```json
{
  "status": "ok",
  "message": "Processing transcription"
}
```

#### Get Transcription Status
```swift
// Swift Usage
let status = try await APIService.shared.getTranscriptionStatus(userId: userId)
```

**Request:**
```
GET /transcribe/status
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "ok",
  "session": {
    "session_id": "session-uuid",
    "status": "processing",
    "created_at": "2023-01-01T00:00:00Z",
    "completed_at": null,
    "result": null,
    "error": null
  }
}
```

### Transcripts Endpoints

#### Get Transcripts
```swift
// Swift Usage
let transcripts = try await APIService.shared.fetchTranscripts()
```

**Request:**
```
GET /transcripts
Authorization: Bearer <token>
```

**Response:**
```json
{
  "data": [
    {
      "transcriptId": "transcript-id",
      "userId": "user-id",
      "text": "Transcribed text",
      "timestamp": "2023-01-01T00:00:00Z",
      "audioUrl": "https://s3.amazonaws.com/audio-file.mp3",
      "originalText": null,
      "isFlagged": false,
      "sessionId": "session-uuid"
    }
  ]
}
```

## Error Handling

The API returns structured error responses:

```json
{
  "error": "Error message",
  "message": "Additional details",
  "status": "error"
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

## Testing

Use the provided test file to verify the integration:

```bash
# Run with backend in test mode
SKIP_AUTH=true mix phx.server

# Run the test
swift test_fixed_endpoints.swift
```

## Key Changes Made

1. **Fixed endpoint paths** to match backend routes
2. **Updated request payloads** to match backend expectations
3. **Added response wrapper models** for GET endpoints
4. **Improved error handling** with detailed error messages
5. **Fixed data model mappings** between Swift and Elixir

## Notes

- The backend extracts user ID from JWT token claims, not from request body
- All timestamps use ISO8601 format
- UUIDs are used for most entity IDs
- The backend supports pagination for list endpoints (add `limit` and `start_key` parameters)