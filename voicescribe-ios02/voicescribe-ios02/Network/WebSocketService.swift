//
//  WebSocketService.swift
//  VoiceScribe
//
//  Created on 13.12.2025.
//

import Foundation
import Combine

class WebSocketService: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketService()
    
    @Published var isConnected = false
    @Published var receivedMessage: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private let decoder = JSONDecoder()
    
    // Phoenix Channels specific
    private var ref: Int = 1
    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 30.0
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        guard !isConnected else { return }
        
        let url = AppConfiguration.websocketURL
        webSocketTask = urlSession.webSocketTask(with: url)
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
    
    // MARK: - Phoenix Protocol
    
    func joinChannel(topic: String, payload: [String: Any] = [:]) {
        let message = PhoenixMessage(
            joinRef: nil,
            ref: String(ref),
            topic: topic,
            event: "phx_join",
            payload: payload
        )
        sendMessage(message)
        ref += 1
    }
    
    func leaveChannel(topic: String) {
        let message = PhoenixMessage(
            joinRef: nil,
            ref: String(ref),
            topic: topic,
            event: "phx_leave",
            payload: [:]
        )
        sendMessage(message)
        ref += 1
    }
    
    func push(topic: String, event: String, payload: [String: Any]) {
        let message = PhoenixMessage(
            joinRef: nil,
            ref: String(ref),
            topic: topic,
            event: event,
            payload: payload
        )
        sendMessage(message)
        ref += 1
    }
    
    // MARK: - Audio Streaming
    
    func sendAudioData(_ data: Data, topic: String) {
        // Encode binary data to Base64 to send via JSON text frame as Phoenix expects
        // Or handle binary frames if the server supports it directly for that channel
        // For standard Phoenix channels, JSON payload with base64 string is common
        // But for high performance, we might want binary frames.
        // Let's assume standard Phoenix JSON for now for commands, and maybe optimized for audio later.
        //
        // NOTE: Phoenix Channels support binary frames as well.
        // [join_ref, ref, topic, event, payload]
        
        // For simplicity in this iteration, we'll send it as a custom event "audio_data"
        let payload: [String: Any] = ["data": data.base64EncodedString()]
        push(topic: topic, event: "audio_data", payload: payload)
    }
    
    // MARK: - Internal
    
    private func sendMessage(_ message: PhoenixMessage) {
        guard let json = try? JSONSerialization.data(withJSONObject: message.toArray(), options: []) else { return }
        let messageString = URLSessionWebSocketTask.Message.string(String(data: json, encoding: .utf8)!)
        
        webSocketTask?.send(messageString) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.isConnected = false
                self.stopHeartbeat()
            case .success(let message):
                switch message {
                case .string(let text):
                    // Handle Phoenix message
                    // [join_ref, ref, topic, event, payload]
                    DispatchQueue.main.async {
                        self.receivedMessage = text
                    }
                    // Parse and handle specific events (like phx_reply) logic here if needed
                    
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    break
                }
                
                // Continue receiving
                self.receiveMessage()
            }
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        print("WebSocket connected")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        print("WebSocket disconnected")
        stopHeartbeat()
    }
    
    // MARK: - Heartbeat
    
    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendHeartbeat() {
        let message = PhoenixMessage(
            joinRef: nil,
            ref: String(ref),
            topic: "phoenix",
            event: "heartbeat",
            payload: [:]
        )
        sendMessage(message)
        ref += 1
    }
}

// Helper struct for Phoenix Message
struct PhoenixMessage {
    let joinRef: String?
    let ref: String?
    let topic: String
    let event: String
    let payload: [String: Any]
    
    func toArray() -> [Any] {
        return [
            joinRef as Any,
            ref as Any,
            topic,
            event,
            payload
        ]
    }
}
