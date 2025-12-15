//
//  KeyboardWebSocketService.swift
//  VoiceScribeKeyboard
//
//  Created on 15.12.2025.
//

import Foundation
import Combine

// Simplified WebSocket Service for Keyboard Extension to avoid dependency hell
class KeyboardWebSocketService: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = KeyboardWebSocketService()
    
    @Published var isConnected = false
    
    // Hardcoded for now, or read from Info.plist/SharedDefaults if possible
    // Ideally this matches AppConfiguration
    private let websocketURL = URL(string: "wss://api.voicescribe.com/socket/websocket")! // REPLACE WITH REAL URL
    // For local dev: ws://localhost:4000/socket/websocket
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    
    private var ref: Int = 1
    private var heartbeatTimer: Timer?
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        guard !isConnected else { return }
        
        webSocketTask = urlSession.webSocketTask(with: websocketURL)
        webSocketTask?.resume()
        
        receiveMessage()
        startHeartbeat()
    }
    
    func disconnect() {
        stopHeartbeat()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    func sendAudioData(_ data: Data, topic: String) {
        let payload: [String: Any] = ["data": data.base64EncodedString()]
        push(topic: topic, event: "audio_data", payload: payload)
    }
    
    // MARK: - Phoenix
    
    func push(topic: String, event: String, payload: [String: Any]) {
        let message: [Any] = [
            nil as Any?,
            String(ref),
            topic,
            event,
            payload
        ]
        
        sendMessage(message)
        ref += 1
    }
    
    private func sendMessage(_ messageArray: [Any]) {
        guard let json = try? JSONSerialization.data(withJSONObject: messageArray, options: []) else { return }
        let messageString = URLSessionWebSocketTask.Message.string(String(data: json, encoding: .utf8)!)
        
        webSocketTask?.send(messageString) { error in
            if let error = error {
                print("KeyboardWS Error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self.handleMessage(text)
                }
                self.receiveMessage()
            case .failure:
                self.isConnected = false
                self.stopHeartbeat()
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        // Simple parse for transcript logic
        guard let data = text.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any],
              jsonArray.count >= 5,
              let event = jsonArray[3] as? String,
              let payload = jsonArray[4] as? [String: Any] else { return }
              
        if event == "transcript_content", let content = payload["content"] as? String {
             DispatchQueue.main.async {
                 NotificationCenter.default.post(name: Notification.Name("receivedTranscript"), object: nil, userInfo: ["content": content])
             }
        }
    }
    
    // MARK: - Delegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async { self.isConnected = true }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async { self.isConnected = false }
    }
    
    // MARK: - Heartbeat
    
    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.push(topic: "phoenix", event: "heartbeat", payload: [:])
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
}
