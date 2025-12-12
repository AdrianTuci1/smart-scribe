//
//  DictionaryEntry.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation

struct DictionaryEntry: Identifiable, Codable {
    let id: UUID
    var term: String
    var definition: String
    let date: Date
    var tags: [String]
    var examples: [String]
    var isFavorite: Bool
    var transcriptId: UUID?
    
    init(
        id: UUID = UUID(),
        term: String,
        definition: String,
        date: Date = Date(),
        tags: [String] = [],
        examples: [String] = [],
        isFavorite: Bool = false,
        transcriptId: UUID? = nil
    ) {
        self.id = id
        self.term = term
        self.definition = definition
        self.date = date
        self.tags = tags
        self.examples = examples
        self.isFavorite = isFavorite
        self.transcriptId = transcriptId
    }
    
    // Computed properties
    var previewDefinition: String {
        if definition.count <= 100 {
            return definition
        }
        return String(definition.prefix(97)) + "..."
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Methods
    mutating func addExample(_ example: String) {
        examples.append(example)
    }
    
    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }
    
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}