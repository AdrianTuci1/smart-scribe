import Foundation

enum MessageContext: String, Codable, CaseIterable {
    case personalMessages = "Personal messages"
    case workMessages = "Work messages"
    case email = "Email"
    case other = "Other"
}

enum WritingStyle: String, Codable, CaseIterable {
    case formal = "Formal"
    case casual = "Casual"
    case veryCasual = "Very casual"
    
    var description: String {
        switch self {
        case .formal:
            return "Caps + Punctuation"
        case .casual:
            return "Caps + Less punctuation"
        case .veryCasual:
            return "No Caps + Less punctuation"
        }
    }
    
    var example: String {
        switch self {
        case .formal:
            return "Hey, are you free for lunch tomorrow? Let's do 12 if that works for you."
        case .casual:
            return "Hey are you free for lunch tomorrow? Let's do 12 if that works for you"
        case .veryCasual:
            return "hey are you free for lunch tomorrow? let's do 12 if that works for you"
        }
    }
}

struct StylePreference: Codable {
    var context: MessageContext
    var style: WritingStyle
}
