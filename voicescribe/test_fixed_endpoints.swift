import Foundation

// Test file to verify the fixed API endpoints
// This test file demonstrates the correct usage of the fixed APIService methods

// Test without authentication token (using SKIP_AUTH=true on backend)
// No token needed when backend runs with SKIP_AUTH=true

// Test the fixed endpoints
print("Testing Fixed VoiceScribe API Endpoints")
print("=====================================")

// MARK: - Test Snippets Endpoints
print("\n1. Testing Snippets Endpoints:")

// Test fetchSnippets
print("Testing fetchSnippets...")
let snippetsURL = URL(string: "http://localhost:4000/api/v1/config/snippets")!
var snippetsRequest = URLRequest(url: snippetsURL)
snippetsRequest.httpMethod = "GET"
// No auth header needed when SKIP_AUTH=true

let snippetsTask = URLSession.shared.dataTask(with: snippetsRequest) { data, response, error in
    if let error = error {
        print("❌ Error fetching snippets: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for snippets")
        return
    }
    
    print("✅ Snippets response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
    }
}

// Test saveSnippets
print("Testing saveSnippets...")
let saveSnippetsURL = URL(string: "http://localhost:4000/api/v1/config/snippets/save")!
var saveSnippetsRequest = URLRequest(url: saveSnippetsURL)
saveSnippetsRequest.httpMethod = "POST"
saveSnippetsRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
// No auth header needed when SKIP_AUTH=true

let snippetsData = [
    "snippets": [
        ["id": UUID().uuidString, "title": "Test Snippet 1", "content": "Test content 1"],
        ["id": UUID().uuidString, "title": "Test Snippet 2", "content": "Test content 2"]
    ]
]

if let jsonData = try? JSONSerialization.data(withJSONObject: snippetsData) {
    saveSnippetsRequest.httpBody = jsonData
}

let saveSnippetsTask = URLSession.shared.dataTask(with: saveSnippetsRequest) { data, response, error in
    if let error = error {
        print("❌ Error saving snippets: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for save snippets")
        return
    }
    
    print("✅ Save snippets response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
    }
}

// MARK: - Test Dictionary Endpoints
print("\n2. Testing Dictionary Endpoints:")

// Test fetchDictionary
print("Testing fetchDictionary...")
let dictionaryURL = URL(string: "http://localhost:4000/api/v1/config/dictionary")!
var dictionaryRequest = URLRequest(url: dictionaryURL)
dictionaryRequest.httpMethod = "GET"
// No auth header needed when SKIP_AUTH=true

let dictionaryTask = URLSession.shared.dataTask(with: dictionaryRequest) { data, response, error in
    if let error = error {
        print("❌ Error fetching dictionary: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for dictionary")
        return
    }
    
    print("✅ Dictionary response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
    }
}

// Test saveDictionary
print("Testing saveDictionary...")
let saveDictionaryURL = URL(string: "http://localhost:4000/api/v1/config/dictionary/save")!
var saveDictionaryRequest = URLRequest(url: saveDictionaryURL)
saveDictionaryRequest.httpMethod = "POST"
saveDictionaryRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
// No auth header needed when SKIP_AUTH=true

let dictionaryData = [
    "dictionary": [
        "entries": [
            ["id": UUID().uuidString, "incorrect_word": "teh", "correct_word": "the"],
            ["id": UUID().uuidString, "incorrect_word": "recieve", "correct_word": "receive"],
            ["id": UUID().uuidString, "incorrect_word": "wich", "correct_word": "which"]
        ]
    ]
]

if let jsonDictData = try? JSONSerialization.data(withJSONObject: dictionaryData) {
    saveDictionaryRequest.httpBody = jsonDictData
}

let saveDictionaryTask = URLSession.shared.dataTask(with: saveDictionaryRequest) { data, response, error in
    if let error = error {
        print("❌ Error saving dictionary: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for save dictionary")
        return
    }
    
    print("✅ Save dictionary response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
    }
}

// MARK: - Test Notes Endpoints
print("\n3. Testing Notes Endpoints:")

// Test createNote first
print("Testing createNote...")
let createNoteURL = URL(string: "http://localhost:4000/api/v1/notes")!
var createNoteRequest = URLRequest(url: createNoteURL)
createNoteRequest.httpMethod = "POST"
createNoteRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

let noteData = [
    "title": "Test Note",
    "content": "This is a test note created via API",
    "timestamp": ISO8601DateFormatter().string(from: Date())
]

if let jsonNoteData = try? JSONSerialization.data(withJSONObject: noteData) {
    createNoteRequest.httpBody = jsonNoteData
}

let createNoteTask = URLSession.shared.dataTask(with: createNoteRequest) { data, response, error in
    if let error = error {
        print("❌ Error creating note: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for create note")
        return
    }
    
    print("✅ Create note response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
    }
}

// Test fetchNotes
print("Testing fetchNotes...")
let notesURL = URL(string: "http://localhost:4000/api/v1/notes")!
var notesRequest = URLRequest(url: notesURL)
notesRequest.httpMethod = "GET"
// No auth header needed when SKIP_AUTH=true

let notesTask = URLSession.shared.dataTask(with: notesRequest) { data, response, error in
    if let error = error {
        print("❌ Error fetching notes: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for notes")
        return
    }
    
    print("✅ Notes response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
    }
}

// MARK: - Test Transcripts Endpoints
print("\n4. Testing Transcripts Endpoints:")

// Test createTranscript
print("Testing createTranscript...")
let createTranscriptURL = URL(string: "http://localhost:4000/api/v1/transcripts")!
var createTranscriptRequest = URLRequest(url: createTranscriptURL)
createTranscriptRequest.httpMethod = "POST"
createTranscriptRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

let transcriptData: [String: Any] = [
    "id": UUID().uuidString,
    "title": "Test Transcript", 
    "content": "This is a test transcript created via API",
    "status": "completed",
    "duration": 120
]

if let jsonTranscriptData = try? JSONSerialization.data(withJSONObject: transcriptData) {
    createTranscriptRequest.httpBody = jsonTranscriptData
}

let createTranscriptTask = URLSession.shared.dataTask(with: createTranscriptRequest) { data, response, error in
    if let error = error {
        print("❌ Error creating transcript: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for create transcript")
        return
    }
    
    print("✅ Create transcript response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
    }
}

// Test fetchTranscripts
print("Testing fetchTranscripts...")
let transcriptsURL = URL(string: "http://localhost:4000/api/v1/transcripts")!
var transcriptsRequest = URLRequest(url: transcriptsURL)
transcriptsRequest.httpMethod = "GET"
// No auth header needed when SKIP_AUTH=true

let transcriptsTask = URLSession.shared.dataTask(with: transcriptsRequest) { data, response, error in
    if let error = error {
        print("❌ Error fetching transcripts: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for transcripts")
        return
    }
    
    print("✅ Transcripts response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
    }
}

// MARK: - Execute all tests
print("\nExecuting all tests...")
print("Make sure the backend is running with SKIP_AUTH=true for testing")
print("Run: SKIP_AUTH=true mix phx.server")

snippetsTask.resume()
saveSnippetsTask.resume()
dictionaryTask.resume()
saveDictionaryTask.resume()
createNoteTask.resume()
notesTask.resume()
createTranscriptTask.resume()
transcriptsTask.resume()

// Wait for all requests to complete
RunLoop.main.run(until: Date(timeIntervalSinceNow: 10))

print("\nTest execution completed!")
print("=====================================")