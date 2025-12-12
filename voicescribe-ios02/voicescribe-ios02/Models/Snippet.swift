//
//  Snippet.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation

struct Snippet: Identifiable, Codable {
    let id: UUID
    var title: String
    let date: Date
    var content: String
    var transcriptId: UUID?
    var startTime: TimeInterval?
    var endTime: TimeInterval?
    var tags: [String]
    var isFavorite: Bool
    var category: SnippetCategory
    
    enum SnippetCategory: String, CaseIterable, Codable {
        case important = "Important"
        case actionItem = "Action Item"
        case question = "Question"
        case decision = "Decision"
        case idea = "Idea"
        case quote = "Quote"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .important:
                return "exclamationmark.circle.fill"
            case .actionItem:
                return "checkmark.circle.fill"
            case .question:
                return "questionmark.circle.fill"
            case .decision:
                return "gavel"
            case .idea:
                return "lightbulb.fill"
            case .quote:
                return "quote.bubble.fill"
            case .other:
                return "doc.fill"
            }
        }
        
        var color: String {
            switch self {
            case .important:
                return "red"
            case .actionItem:
                return "green"
            case .question:
                return "blue"
            case .decision:
                return "purple"
            case .idea:
                return "orange"
            case .quote:
                return "indigo"
            case .other:
                return "gray"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        content: String,
        transcriptId: UUID? = nil,
        startTime: TimeInterval? = nil,
        endTime: TimeInterval? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        category: SnippetCategory = .other
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.content = content
        self.transcriptId = transcriptId
        self.startTime = startTime
        self.endTime = endTime
        self.tags = tags
        self.isFavorite = isFavorite
        self.category = category
    }
    
    // Computed properties
    var previewText: String {
        if content.count <= 80 {
            return content
        }
        return String(content.prefix(77)) + "..."
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedTimeRange: String? {
        guard let startTime = startTime, let endTime = endTime else { return nil }
        
        let startMinutes = Int(startTime) / 60
        let startSeconds = Int(startTime) % 60
        
        let endMinutes = Int(endTime) / 60
        let endSeconds = Int(endTime) % 60
        
        return String(format: "%d:%02d - %d:%02d", startMinutes, startSeconds, endMinutes, endSeconds)
    }
}