import Foundation

struct Transcript: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let text: String
    let timestamp: Date
    let audioUrl: String?
    let originalText: String?  // For undo AI edit functionality
    let isFlagged: Bool
    let sessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "transcriptId"
        case userId
        case text
        case timestamp
        case audioUrl
        case originalText
        case isFlagged
        case sessionId
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         text: String,
         timestamp: Date = Date(),
         audioUrl: String? = nil,
         originalText: String? = nil,
         isFlagged: Bool = false,
         sessionId: String? = nil) {
        self.id = id
        self.userId = userId
        self.text = text
        self.timestamp = timestamp
        self.audioUrl = audioUrl
        self.originalText = originalText
        self.isFlagged = isFlagged
        self.sessionId = sessionId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        text = try container.decode(String.self, forKey: .text)
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)
        originalText = try container.decodeIfPresent(String.self, forKey: .originalText)
        isFlagged = try container.decodeIfPresent(Bool.self, forKey: .isFlagged) ?? false
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        
        // Handle timestamp - try ISO8601 first, then Unix timestamp
        if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: timestampString) {
                timestamp = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                timestamp = formatter.date(from: timestampString) ?? Date()
            }
        } else if let unixTimestamp = try? container.decode(Double.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: unixTimestamp)
        } else {
            timestamp = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(audioUrl, forKey: .audioUrl)
        try container.encodeIfPresent(originalText, forKey: .originalText)
        try container.encode(isFlagged, forKey: .isFlagged)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
    }
    
    // Helper to check if AI edit can be undone
    var canUndoAIEdit: Bool {
        originalText != nil && originalText != text
    }
    
    // Create a copy with updated text (for AI edit undo)
    func withUndoneAIEdit() -> Transcript {
        guard let original = originalText else { return self }
        return Transcript(
            id: id,
            userId: userId,
            text: original,
            timestamp: timestamp,
            audioUrl: audioUrl,
            originalText: nil,
            isFlagged: isFlagged,
            sessionId: sessionId
        )
    }
    
    // Create a copy with toggled flag
    func withToggledFlag() -> Transcript {
        return Transcript(
            id: id,
            userId: userId,
            text: text,
            timestamp: timestamp,
            audioUrl: audioUrl,
            originalText: originalText,
            isFlagged: !isFlagged,
            sessionId: sessionId
        )
    }
}

// MARK: - Transcript Grouping Helper
extension Array where Element == Transcript {
    /// Groups transcripts by date (Today, Yesterday, or specific date)
    func groupedByDate() -> [(String, [Transcript])] {
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: self) { transcript -> String in
            if calendar.isDateInToday(transcript.timestamp) {
                return "TODAY"
            } else if calendar.isDateInYesterday(transcript.timestamp) {
                return "YESTERDAY"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                return formatter.string(from: transcript.timestamp).uppercased()
            }
        }
        
        // Sort groups by date (most recent first)
        return grouped.sorted { group1, group2 in
            guard let date1 = self.first(where: { 
                let key = calendar.isDateInToday($0.timestamp) ? "TODAY" : 
                         calendar.isDateInYesterday($0.timestamp) ? "YESTERDAY" : 
                         DateFormatter().string(from: $0.timestamp).uppercased()
                return key == group1.key
            })?.timestamp,
                  let date2 = self.first(where: {
                let key = calendar.isDateInToday($0.timestamp) ? "TODAY" : 
                         calendar.isDateInYesterday($0.timestamp) ? "YESTERDAY" : 
                         DateFormatter().string(from: $0.timestamp).uppercased()
                return key == group2.key
            })?.timestamp else {
                return false
            }
            return date1 > date2
        }.map { ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }
}

