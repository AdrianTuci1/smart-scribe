import Foundation
import Combine
import AppKit

class TranscriptionViewModel: ObservableObject {
    @Published var finalText: NSAttributedString = NSAttributedString(string: "")
    @Published var provisionalText: String = ""
    @Published var isRecording: Bool = false
    
    private var recordingManager = RecordingManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Subscribe to recording state changes
        recordingManager.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        // Subscribe to transcription state changes
        recordingManager.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleTranscriptionState(state)
            }
            .store(in: &cancellables)
        
        // Subscribe to last transcription
        recordingManager.$lastTranscription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                if !text.isEmpty {
                    self?.appendTranscription(text)
                }
            }
            .store(in: &cancellables)
    }
    
    func toggleRecording() {
        recordingManager.toggleRecording()
    }
    
    private func appendTranscription(_ text: String) {
        // Append new text to existing attributed string
        let mutableText = NSMutableAttributedString(attributedString: finalText)
        let newText = NSAttributedString(string: text + " ", attributes: [.font: NSFont.systemFont(ofSize: 14)])
        mutableText.append(newText)
        finalText = mutableText
    }
    
    private func handleTranscriptionState(_ state: TranscriptionSessionState) {
        switch state {
        case .idle:
            // No active session
            provisionalText = ""
            
        case .recording:
            // Session is recording
            provisionalText = ""
            
        case .processing:
            // Transcription is being processed
            DispatchQueue.main.async {
                self.provisionalText = "Processing transcription..."
            }
            
        case .completed(let text):
            // Transcription completed
            DispatchQueue.main.async {
                self.provisionalText = ""
                if !text.isEmpty {
                    self.appendTranscription(text)
                }
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
