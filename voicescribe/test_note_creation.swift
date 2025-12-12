import Foundation

// Define Note model inline for standalone testing
struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), content: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Helper to create note for backend (ensures dates are included)
    func toBackendDictionary() -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return [
            "id": id.uuidString,
            "content": content,
            "created_at": formatter.string(from: createdAt),
            "updated_at": formatter.string(from: updatedAt)
        ]
    }
}

// Test file to verify note creation with proper date handling
print("Testing Note Creation with Date Handling")
print("=====================================")

// Test creating a note with specific dates
let testNote = Note(
    id: UUID(),
    content: "Test note content with specific dates",
    createdAt: Date(),
    updatedAt: Date()
)

// Convert to backend dictionary
let backendDict = testNote.toBackendDictionary()
print("Note converted to backend format:")
print(backendDict)

// Test actual API call
let baseURL = "http://localhost:4000/api/v1"
let url = URL(string: "\(baseURL)/notes")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.addValue("application/json", forHTTPHeaderField: "Content-Type")
// No auth header needed when SKIP_AUTH=true

let noteData = try? JSONSerialization.data(withJSONObject: backendDict)
request.httpBody = noteData

print("\nSending request to create note...")
print("URL: \(url.absoluteString)")
print("Method: POST")
print("Headers: Content-Type: application/json")

if let jsonData = noteData, let jsonString = String(data: jsonData, encoding: .utf8) {
    print("Body: \(jsonString)")
}

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("❌ Error creating note: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response for note creation")
        return
    }
    
    print("✅ Note creation response status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
        
        // Try to decode the response back to a Note
        if let createdNote = try? JSONDecoder().decode(Note.self, from: data) {
            print("\n✅ Successfully decoded created note:")
            print("ID: \(createdNote.id)")
            print("Content: \(createdNote.content)")
            print("Created At: \(createdNote.createdAt)")
            print("Updated At: \(createdNote.updatedAt)")
        } else {
            print("❌ Failed to decode created note from response")
        }
    }
}

task.resume()

// Wait for request to complete
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))

print("\nNote creation test completed!")
print("=====================================")