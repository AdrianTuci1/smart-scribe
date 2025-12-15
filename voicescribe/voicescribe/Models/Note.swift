import Foundation

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var content: String
    var title: String?
    var userId: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "noteId"
        case content
        case title
        case userId
        case createdAt = "timestamp"
        // updatedAt is not in the JSON response shown, so we'll omit it from keys or make it optional/computed
    }
    
    init(id: UUID = UUID(), content: String, title: String? = nil, userId: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.title = title
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Custom decoding to handle date formats and UUID conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode ID (handle string to UUID)
        if let idString = try? container.decode(String.self, forKey: .id),
           let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            id = UUID() // Fallback or throw? Fallback for robustness
        }
        
        content = try container.decode(String.self, forKey: .content)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        
        // Handle timestamp
        if let timestampString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: timestampString) {
                createdAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: timestampString) ?? Date()
            }
        } else {
            createdAt = Date()
        }
        
        // Default updatedAt to createdAt since it's missing in the response
        updatedAt = createdAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(userId, forKey: .userId)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
    }
    
    // Helper to create note for backend
    func toBackendDictionary() -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var dict: [String: Any] = [
            "noteId": id.uuidString, // Backend expects noteId likely based on GET response, but need to check POST
            "content": content,
            "timestamp": formatter.string(from: createdAt)
        ]
        
        if let title = title {
            dict["title"] = title
        }
        
        if let userId = userId {
            dict["userId"] = userId
        }
        
        return dict
    }
}
