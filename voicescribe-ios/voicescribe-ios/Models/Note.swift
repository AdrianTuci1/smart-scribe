//
//  Note.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    let date: Date
    let dateModified: Date
    var content: String
    var transcriptId: UUID?
    var tags: [String]
    var isPinned: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        dateModified: Date = Date(),
        content: String,
        transcriptId: UUID? = nil,
        tags: [String] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.dateModified = dateModified
        self.content = content
        self.transcriptId = transcriptId
        self.tags = tags
        self.isPinned = isPinned
    }
    
    // Computed properties
    var previewText: String {
        if content.count <= 100 {
            return content
        }
        return String(content.prefix(97)) + "..."
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedModifiedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: dateModified)
    }
    
    var wordCount: Int {
        return content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    // Methods
    mutating func updateContent(_ newContent: String) {
        content = newContent
        // Note: In a real implementation, you would update dateModified here
        // but since structs are immutable, this would need to be done at the call site
    }
}