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
    private let webSocketService = WebSocketService.shared // Use WebSocket service
    private var audioChunks: [Data] = []
    private var currentSessionId: String?
    
    private init() {
        setupWebSocketCallbacks()
    }
    
    var onTranscriptReceived: ((String) -> Void)?
    
    private func setupWebSocketCallbacks() {
        webSocketService.onTranscriptionComplete = { [weak self] text in
            DispatchQueue.main.async {
                self?.sessionState = .completed(text: text)
            }
        }
        
        webSocketService.onTranscriptMessage = { [weak self] text in
            DispatchQueue.main.async {
                // Pass real-time transcript to whoever is listening (RecordingManager)
                self?.onTranscriptReceived?(text)
                // Also update session state if needed, or just keep it recording
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Start a new transcription session
    func startTranscription(userId: String) async throws {
        guard sessionState == .idle else {
            throw TranscriptionError.alreadyRecording
        }
        
        // For WebSocket flow, we just connect. The "start_stream" is handled in joinChannel inside connect
        // But actually we might want to start logging session in DB separately?
        // For now let's mirror existing behavior - assume backend creates session on join or we just go with it.
        // Actually, the previous implementation called `apiService.startTranscriptionSession`. 
        // We can keep that if we want a DB record, but for streaming we primarily need the socket.
        // Let's keep the DB call for robust session tracking if needed, OR just rely on WS.
        // The user said "I just want it to start and stop". 
        // Let's connect WS.
        
        DispatchQueue.main.async {
            self.currentSessionId = userId // Use userId as session for simplicity in WS topic
            self.sessionState = .recording(sessionId: userId)
            self.audioChunks = []
            
            // Connect WebSocket
            let token = AuthService.shared.token
            self.webSocketService.connect(userId: userId, token: token)
        }
    }
    
    /// Add an audio chunk to the current session
    func addAudioChunk(_ chunk: Data) async throws {
        guard case .recording = sessionState, let userId = currentSessionId else {
            return // Ignore if not recording or no user ID
        }
        
        // Send chunk via WebSocket
        webSocketService.sendAudioChunk(data: chunk, userId: userId)
    }
    
    /// Finish the current transcription session and start processing
    func finishTranscription() async throws {
        guard case .recording = sessionState else {
            throw TranscriptionError.notRecording
        }
        
        DispatchQueue.main.async {
            self.sessionState = .processing
            // Signal to stop stream, but keep socket open for result
            if let userId = self.currentSessionId { 
                self.webSocketService.stopStream(userId: userId)
            }
        }
    }
    
    /// Cancel the current session
    func cancelTranscription() {
        DispatchQueue.main.async {
             self.webSocketService.disconnect()
             self.sessionState = .idle
             self.currentSessionId = nil
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
