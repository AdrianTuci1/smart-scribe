import Foundation
import Combine

// MARK: - Transcription Session State
enum TranscriptionSessionState: Equatable, Sendable {
    case idle
    case recording(sessionId: String)
    case processing
    case completed(text: String)
    case error(String)
    
    var sessionId: String? {
        switch self {
        case .recording(let sessionId):
            return sessionId
        default:
            return nil
        }
    }
    
    var isRecording: Bool {
        if case .recording = self {
            return true
        }
        return false
    }
}

// MARK: - Transcription Service
class TranscriptionService: ObservableObject {
    static let shared = TranscriptionService()
    
    // MARK: - Published Properties
    @Published var sessionState: TranscriptionSessionState = .idle
    
    // MARK: - Private Properties
    private let apiService = APIService.shared
    private var audioChunks: [Data] = []
    private var currentSessionId: String?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start a new transcription session
    func startTranscription(userId: String) async throws {
        guard sessionState == .idle else {
            throw TranscriptionError.alreadyRecording
        }
        
        do {
            let response = try await apiService.startTranscriptionSession(userId: userId)
            
            DispatchQueue.main.async {
                self.currentSessionId = response.sessionId
                self.sessionState = .recording(sessionId: response.sessionId)
                self.audioChunks = []
            }
        } catch {
            throw error
        }
    }
    
    /// Add an audio chunk to the current session
    func addAudioChunk(_ chunk: Data) async throws {
        guard case .recording = sessionState else {
            throw TranscriptionError.notRecording
        }
        
        audioChunks.append(chunk)
        
        // Send chunk to server
        do {
            // Compress chunk with gzip before sending
            let compressedChunk = compressData(chunk)
            try await apiService.uploadTranscriptionChunk(
                userId: getUserId(),
                chunk: compressedChunk.base64EncodedString()
            )
        } catch {
            print("Failed to upload chunk: \(error)")
            throw error
        }
    }
    
    /// Finish the current transcription session and start processing
    func finishTranscription() async throws {
        guard case .recording = sessionState else {
            throw TranscriptionError.notRecording
        }
        
        guard let sessionId = currentSessionId else {
            throw TranscriptionError.noSession
        }
        
        do {
            DispatchQueue.main.async {
                self.sessionState = .processing
            }
            
            // Signal server to finish and process
            try await apiService.finishTranscriptionSession(userId: getUserId())
            
            // Start polling for results
            await pollForResults(sessionId: sessionId)
            
        } catch {
            DispatchQueue.main.async {
                self.sessionState = .error(error.localizedDescription)
            }
            throw error
        }
    }
    
    /// Cancel the current session
    func cancelTranscription() {
        guard currentSessionId != nil else { return }
        
        DispatchQueue.main.async {
            self.sessionState = .idle
            self.currentSessionId = nil
            self.audioChunks = []
        }
    }
    
    // MARK: - Private Methods
    
    private func pollForResults(sessionId: String) async {
        let maxAttempts = 30  // 30 attempts = 5 minutes max
        let pollingInterval: TimeInterval = 10  // 10 seconds between attempts
        
        for _ in 1...maxAttempts {
            do {
                let status = try await apiService.getTranscriptionStatus(userId: getUserId())
                
                if let session = status.session {
                    switch session.status {
                    case "completed":
                        if let result = session.result {
                            DispatchQueue.main.async {
                                self.sessionState = .completed(text: result)
                            }
                        }
                        return
                    case "failed":
                        if let error = session.error {
                            DispatchQueue.main.async {
                                self.sessionState = .error(error)
                            }
                        }
                        return
                    default:
                        // Still processing, continue polling
                        break
                    }
                }
                
                // Wait before next poll
                try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                
            } catch {
                print("Error polling transcription status: \(error)")
                DispatchQueue.main.async {
                    self.sessionState = .error(error.localizedDescription)
                }
                return
            }
        }
        
        // Max attempts reached
        DispatchQueue.main.async {
            self.sessionState = .error("Transcription timed out")
        }
    }
    
    // Add method to show PLEASE_HOLD notification after 5 seconds
    private func showPleaseHoldNotificationIfNeeded(attempt: Int) {
        // Show PLEASE_HOLD after 5 seconds (after first attempt)
        if attempt > 0 {
            DispatchQueue.main.async {
                // This would be handled by the UI component
                // In a real implementation, we'd use notification center
                print("PLEASE_HOLD: Vă rugăm să așteptați. Procesarea durează mai mult decât de obicei.")
            }
        }
    }
    
    // Add method to handle slow processing
    private func handleSlowProcessing() {
        DispatchQueue.main.async {
            // This would be handled by the UI component
            print("SLOW_PROCESSING: Ne ia mai mult timp decât de obicei. Puteți aștepta sau anula cererea.")
        }
    }
    
    private func getUserId() -> String {
        // Get user ID from auth service
        return AuthService.shared.currentUser?.userId ?? "default_user"
    }
    
    // Compress data using lzfse (Apple's compression algorithm)
    private func compressData(_ data: Data) -> Data {
        do {
            return try (data as NSData).compressed(using: .lzfse) as Data
        } catch {
            print("Failed to compress chunk data: \(error)")
            return data // Return original data if compression fails
        }
    }
}

// MARK: - Transcription Error
enum TranscriptionError: LocalizedError, Equatable {
    case alreadyRecording
    case notRecording
    case noSession
    case networkError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "A transcription session is already active"
        case .notRecording:
            return "No active transcription session"
        case .noSession:
            return "No transcription session available"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - API Response Models
struct StartTranscriptionResponse: Codable {
    let status: String
    let sessionId: String
}

struct TranscriptionStatusResponse: Codable {
    let status: String
    let session: TranscriptionSession?
}

struct TranscriptionSession: Codable {
    let sessionId: String
    let status: String
    let createdAt: String?
    let completedAt: String?
    let result: String?
    let error: String?
}
