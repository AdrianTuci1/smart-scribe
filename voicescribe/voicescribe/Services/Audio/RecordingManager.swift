import Foundation
import Combine
import AVFoundation

/// Central manager for coordinating audio recording and batch transcription
class RecordingManager: ObservableObject {
    static let shared = RecordingManager()
    
    // MARK: - Published Properties
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false
    @Published var amplitudes: [CGFloat] = Array(repeating: 0, count: 7)
    @Published var sessionState: TranscriptionSessionState = .idle
    @Published var lastTranscription: String = ""
    
    // MARK: - Private Properties
    private let audioService = AudioCaptureService.shared
    private let transcriptionService = TranscriptionService.shared
    private let apiService = APIService.shared
    private var amplitudeHistory: [Float] = []
    
    // Expose cancellables for external use
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
        setupAuthBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        
        transcriptionService.$sessionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$sessionState)
        
        // Bind recording state
        audioService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)
            
        // Bind paused state
        audioService.$isPaused
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPaused)
        
        // Bind audio amplitude to waveform visualization
        audioService.$currentAmplitude
            .receive(on: DispatchQueue.main)
            .sink { [weak self] amplitude in
                self?.updateAmplitudes(amplitude)
            }
            .store(in: &cancellables)
        
        // Handle transcription results
        transcriptionService.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .completed(let text) = state {
                    self?.lastTranscription = text
                }
            }
            .store(in: &cancellables)
        
        // Handle audio chunks
        audioService.onAudioChunk = { [weak self] chunk in
            Task {
                do {
                    try await self?.transcriptionService.addAudioChunk(chunk)
                } catch {
                    print("RecordingManager: Failed to send audio chunk: \(error)")
                    DispatchQueue.main.async {
                        self?.sessionState = .error(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func setupAuthBindings() {
        // Update API service token when auth state changes
        AuthService.shared.$token
            .receive(on: DispatchQueue.main)
            .sink { [weak self] token in
                self?.apiService.setAuthToken(token)
            }
            .store(in: &cancellables)
        
        // Set initial token if available
        if let token = AuthService.shared.token {
            apiService.setAuthToken(token)
        }
    }
    
    private func updateAmplitudes(_ amplitude: Float) {
        // Shift amplitudes left and add new one
        var newAmplitudes = amplitudes
        newAmplitudes.removeFirst()
        // Scale amplitude to visual range (3-25)
        let scaledAmplitude = CGFloat(3 + amplitude * 22)
        newAmplitudes.append(scaledAmplitude)
        amplitudes = newAmplitudes
    }
    
    // MARK: - Public Methods
    
    /// Start recording audio and prepare for batch transcription
    func startRecording() {
        // Check microphone permission using PermissionManager
        if PermissionManager.shared.isMicrophonePermissionGranted() {
            startRecordingSession()
        } else {
            // If not determined, we should request it first
            let status = PermissionManager.shared.microphonePermissionStatus
            if status == .notDetermined {
                PermissionManager.shared.requestMicrophonePermission { [weak self] granted in
                    if granted {
                        self?.startRecordingSession()
                    } else {
                        self?.handlePermissionDenied()
                    }
                }
            } else {
                // Denied or restricted
                handlePermissionDenied()
            }
        }
    }
    
    private func startRecordingSession() {
        Task {
            do {
                // Start transcription session
                try await transcriptionService.startTranscription(userId: getUserId())
                
                // Start audio recording
                try audioService.startRecording()
                
                print("RecordingManager: Recording started")
            } catch {
                print("RecordingManager: Failed to start recording: \(error)")
                DispatchQueue.main.async {
                    self.sessionState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func handlePermissionDenied() {
        print("RecordingManager: Microphone permission not granted")
        // Open settings for user to grant permission
        DispatchQueue.main.async {
            self.sessionState = .error("Microphone permission is required. Please grant it in System Settings.")
            PermissionManager.shared.openMicrophoneSettings()
        }
    }
    
    /// Stop recording and finalize transcription
    func stopRecording() {
        audioService.stopRecording()
        
        Task {
            do {
                try await transcriptionService.finishTranscription()
            } catch {
                print("RecordingManager: Failed to finish transcription: \(error)")
                DispatchQueue.main.async {
                    self.sessionState = .error(error.localizedDescription)
                }
            }
        }
        
        DispatchQueue.main.async {
            // Reset amplitudes to baseline
            self.amplitudes = Array(repeating: 3, count: 7)
        }
        
        print("RecordingManager: Recording stopped")
    }
    
    /// Cancel recording without saving
    func cancelRecording() {
        audioService.stopRecording() // Ensure audio is stopped
        transcriptionService.cancelTranscription()
        
        DispatchQueue.main.async {
            self.amplitudes = Array(repeating: 3, count: 7)
            self.lastTranscription = ""
        }
        
        print("RecordingManager: Recording cancelled")
    }
    
    /// Pause recording
    func pauseRecording() {
        audioService.pauseRecording()
    }
    
    /// Resume recording
    func resumeRecording() {
        do {
            try audioService.resumeRecording()
        } catch {
            print("RecordingManager: Failed to resume recording: \(error)")
            DispatchQueue.main.async {
                self.sessionState = .error(error.localizedDescription)
            }
        }
    }
    
    /// Toggle recording state (Start/Stop)
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    /// Toggle pause state
    func togglePause() {
        if isPaused {
            resumeRecording()
        } else {
            pauseRecording()
        }
    }
    
    // MARK: - Private Methods
    
    private func getUserId() -> String {
        // Get user ID from auth service
        return AuthService.shared.currentUser?.userId ?? "default_user"
    }
}
