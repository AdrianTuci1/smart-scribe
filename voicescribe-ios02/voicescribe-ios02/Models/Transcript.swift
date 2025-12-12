//
//  Transcript.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation

struct Transcript: Identifiable, Codable {
    let id: UUID
    var title: String
    let date: Date
    let duration: TimeInterval
    let content: String
    var confidence: Float?
    var fileURL: URL?
    var tags: [String]
    var isBookmarked: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        duration: TimeInterval = 0,
        content: String,
        confidence: Float? = nil,
        fileURL: URL? = nil,
        tags: [String] = [],
        isBookmarked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.content = content
        self.confidence = confidence
        self.fileURL = fileURL
        self.tags = tags
        self.isBookmarked = isBookmarked
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, duration, content, confidence, tags, isBookmarked
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        content = try container.decode(String.self, forKey: .content)
        confidence = try container.decodeIfPresent(Float.self, forKey: .confidence)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isBookmarked = try container.decodeIfPresent(Bool.self, forKey: .isBookmarked) ?? false
        
        // fileURL can't be encoded/decoded directly
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "transcript_\(id.uuidString).m4a"
        fileURL = documentsPath.appendingPathComponent(fileName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(duration, forKey: .duration)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(confidence, forKey: .confidence)
        try container.encode(tags, forKey: .tags)
        try container.encode(isBookmarked, forKey: .isBookmarked)
        // fileURL is not encoded
    }
    
    // Computed properties
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var previewText: String {
        if content.count <= 100 {
            return content
        }
        return String(content.prefix(97)) + "..."
    }
}