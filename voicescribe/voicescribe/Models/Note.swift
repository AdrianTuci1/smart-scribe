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
}
