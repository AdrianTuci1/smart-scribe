//
//  APIService.swift
//  VoiceScribe
//
//  Created on 13.12.2025.
//

import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Snippets
    
    func fetchSnippets() -> AnyPublisher<[Snippet], Error> {
        let url = AppConfiguration.url(for: "snippets")
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Snippet].self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func createSnippet(_ snippet: Snippet) -> AnyPublisher<Snippet, Error> {
        let url = AppConfiguration.url(for: "snippets")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try encoder.encode(snippet)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Snippet.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Notes
    
    func fetchNotes() -> AnyPublisher<[Note], Error> {
        let url = AppConfiguration.url(for: "notes")
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Note].self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Dictionary
    
    func fetchDictionaryEntries() -> AnyPublisher<[DictionaryEntry], Error> {
        let url = AppConfiguration.url(for: "dictionary_entries")
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [DictionaryEntry].self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
