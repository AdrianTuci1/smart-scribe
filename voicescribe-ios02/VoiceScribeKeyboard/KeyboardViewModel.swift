//
//  KeyboardViewModel.swift
//  VoiceScribeKeyboard
//
//  Created on 15.12.2025.
//

import Foundation
import SwiftUI
import Combine

class KeyboardViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var statusMessage: String = "Tap to Record"
    
    private var textDocumentProxy: UITextDocumentProxy
    private var webSocketService = KeyboardWebSocketService.shared
    private var audioService = KeyboardAudioService()
    
    private let appGroupName = "group.com.voicescribe.ios"
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
        setupBindings()
        loadUser()
    }
    
    private func loadUser() {
        if let defaults = UserDefaults(suiteName: appGroupName) {
            self.currentUserId = defaults.string(forKey: "currentUserId")
        }
        
        if currentUserId == nil {
            errorMessage = "Please open the main VoiceScribe app to log in."
        }
    }
    
    private func setupBindings() {
        // Listen for internal transcript notifications (if logic shared)
        // Or if using a dedicated notification for the extension scope
        NotificationCenter.default.publisher(for: .receivedTranscript)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let content = notification.userInfo?["content"] as? String {
                    self?.insertText(content)
                }
            }
            .store(in: &cancellables)
            
        // Observe WebSocket state
        webSocketService.$isConnected
             .receive(on: RunLoop.main)
             .sink { [weak self] connected in
                 if connected {
                     self?.statusMessage = "Listening..."
                 } else if self?.isRecording == true {
                     self?.statusMessage = "Connecting..."
                 }
             }
             .store(in: &cancellables)
    }
    
    func toggleRecording() {
        guard currentUserId != nil else {
            errorMessage = "Please login in main app."
            return
        }
        
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        errorMessage = nil
        isRecording = true
        statusMessage = "Connecting..."
        
        // 1. Connect WS
        webSocketService.connect()
        
        // 2. Start Audio (Give it a moment for WS?)
        // Better flow: WebSocketService should auto-connect but let's ensure
        
        do {
            try audioService.startRecording { [weak self] chunkData in
                guard let self = self else { return }
                guard let userId = self.currentUserId else { return }
                
                // Send stream start if not already (handled by Service usually?)
                // Assuming WebSocketService handles 'on connect' logic or we send manually
                if self.webSocketService.isConnected {
                     // We need to ensure stream is started. 
                     // For now, let's assume sendAudioData handles it or we manually trigger
                     self.webSocketService.sendAudioData(chunkData, topic: "audio:\(userId)")
                }
            }
        } catch {
            errorMessage = "Microphone error: \(error.localizedDescription)"
            isRecording = false
            statusMessage = "Tap to Record"
        }
    }
    
    private func stopRecording() {
        isRecording = false
        statusMessage = "Finalizing..."
        
        audioService.stopRecording()
        
        // Send stop stream text?
        // webSocketService.sendStopStream()
        
        // Wait a bit for final transcript then disconnect?
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.webSocketService.disconnect()
            self?.statusMessage = "Tap to Record"
        }
    }
    
    private func insertText(_ text: String) {
        // Insert text at cursor
        self.textDocumentProxy.insertText(text + " ")
        
        // Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
