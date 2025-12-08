import Foundation

struct DictionaryEntry: Identifiable, Codable {
    let id: UUID
    var incorrectWord: String
    var correctWord: String
    var createdAt: Date
    
    init(id: UUID = UUID(), incorrectWord: String, correctWord: String, createdAt: Date = Date()) {
        self.id = id
        self.incorrectWord = incorrectWord
        self.correctWord = correctWord
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case incorrectWord = "incorrect_word"
        case correctWord = "correct_word"
        case createdAt = "created_at"
    }
}
