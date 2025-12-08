import Foundation
import Combine

/// Service for syncing data (notes, snippets, dictionary) with server
class DataSyncService: ObservableObject {
    static let shared = DataSyncService()
    
    // MARK: - Published Properties
    @Published var isSyncing: Bool = false
    @Published var lastSyncError: String?
    
    // MARK: - Private Properties
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Notes Sync
    
    func syncNote(_ note: Note) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            _ = try await apiService.createNote(note)
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
    
    func deleteNote(_ note: Note) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await apiService.deleteNote(id: note.id.uuidString)
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
    
    func fetchNotes() async throws -> [Note] {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            return try await apiService.fetchNotes()
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Snippets Sync
    
    func syncSnippets(_ snippets: [Snippet]) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await apiService.saveSnippets(snippets)
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
    
    func fetchSnippets() async throws -> [Snippet] {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            return try await apiService.fetchSnippets()
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Dictionary Sync
    
    func syncDictionary(_ dictionary: [DictionaryEntry]) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await apiService.saveDictionary(dictionary)
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
    
    func fetchDictionary() async throws -> [DictionaryEntry] {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            return try await apiService.fetchDictionary()
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Style Preferences Sync
    
    func syncStylePreferences(_ preferences: StylePreference) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await apiService.saveStylePreferences(preferences)
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
    
    func fetchStylePreferences() async throws -> StylePreference {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            return try await apiService.fetchStylePreferences()
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }
}
