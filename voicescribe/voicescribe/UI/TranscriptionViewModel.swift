import Foundation
import Combine
import AppKit

class TranscriptionViewModel: ObservableObject {
    @Published var finalText: NSAttributedString = NSAttributedString(string: "")
    @Published var provisionalText: String = ""
    @Published var isRecording: Bool = false
    
    private var transcriptionService = TranscriptionService.shared
    private var audioService = AudioCaptureService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupTranscriptionService()
        setupAudioService()
    }
    
    private func setupTranscriptionService() {
        // Subscribe to transcription state changes
        transcriptionService.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleTranscriptionState(state)
            }
            .store(in: &cancellables)
    }
    
    private func setupAudioService() {
        // Subscribe to audio chunks
        audioService.onAudioChunk = { [weak self] chunk in
            Task {
                do {
                    try await self?.transcriptionService.addAudioChunk(chunk)
                } catch {
                    print("Failed to add audio chunk: \(error)")
                }
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        do {
            // Start audio capture
            try audioService.startRecording()
            
            // Start transcription session
            let userId = AuthService.shared.currentUser?.userId ?? "default_user"
            Task {
                do {
                    try await transcriptionService.startTranscription(userId: userId)
                    
                    DispatchQueue.main.async {
                        self.isRecording = true
                        self.provisionalText = ""
                        
                        // Show Overlay
                        if let appDelegate = NSApp.delegate as? AppDelegate {
                            appDelegate.overlayManager.showOverlay(isRecording: true)
                        }
                    }
                } catch {
                    print("Failed to start transcription: \(error)")
                    DispatchQueue.main.async {
                        self.isRecording = false
                    }
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        // Stop audio capture
        audioService.stopRecording()
        
        // Finish transcription session
        Task {
            do {
                try await transcriptionService.finishTranscription()
            } catch {
                print("Failed to finish transcription: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.provisionalText = ""
            
            // Hide Overlay
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.overlayManager.showOverlay(isRecording: false)
            }
        }
    }
    
    private func handleTranscriptionState(_ state: TranscriptionSessionState) {
        switch state {
        case .idle:
            // No active session
            break
            
        case .recording:
            // Session is recording
            break
            
        case .processing:
            // Transcription is being processed
            DispatchQueue.main.async {
                self.provisionalText = "Processing transcription..."
            }
            
        case .completed(let text):
            // Transcription completed
            DispatchQueue.main.async {
                // Append new text to existing attributed string
                let mutableText = NSMutableAttributedString(attributedString: self.finalText)
                let newText = NSAttributedString(string: text + " ", attributes: [.font: NSFont.systemFont(ofSize: 14)])
                mutableText.append(newText)
                self.finalText = mutableText
                self.provisionalText = ""
            }
            
        case .error(let message):
            // Transcription failed
            DispatchQueue.main.async {
                self.provisionalText = "Error: \(message)"
            }
        }
    }
    
    // Formatting Helpers
    func applyFormat(_ attribute: NSAttributedString.Key, value: Any) {
        // Apply formatting to selected text in finalText
        // This would need implementation for text selection
    }
}
