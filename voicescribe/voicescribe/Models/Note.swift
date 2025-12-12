import Foundation

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
