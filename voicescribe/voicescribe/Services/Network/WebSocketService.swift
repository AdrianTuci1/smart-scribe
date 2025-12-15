import Foundation
import Combine

class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    
    // MARK: - Private Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private var pingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Callbacks
    var onTranscriptionComplete: ((String) -> Void)?
    var onTranscriptMessage: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    private init() {}
    
    // MARK: - Public Methods
    
    func connect(userId: String, token: String?) {
        guard !isConnected else { return }
        
        // Parse the existing base URL to get scheme, host, and port
        guard let apiBaseURLComponents = URLComponents(string: CognitoConfig.apiBaseUrl),
              let host = apiBaseURLComponents.host else {
            print("WebSocketService: Invalid API Base URL")
            return
        }
        
        // Construct new URL components for the WebSocket connection
        var components = URLComponents()
        components.scheme = apiBaseURLComponents.scheme == "https" ? "wss" : "ws"
        components.host = host
        components.port = apiBaseURLComponents.port
        components.path = "/socket/websocket"
        
        // Add query items
        var queryItems = [URLQueryItem]()
        if let token = token {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else { return }
        
        let request = URLRequest(url: url)
        // Phoenix channels often expect vsn param
        // request.url = url.appending("vsn", "2.0.0") 
        // But standards vary, let's try standard connection first. 
        // Phoenix default is separate. We'll join the channel manually after connect.
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        receiveMessage()
        
        // Phoenix Join Protocol
        // We need to join "audio:session_id"
        // Let's us userId as sessionId for now to match HTTP implementation
        joinChannel(topic: "audio:\(userId)", userId: userId)
        
        self.isConnected = true
        startPing()
        
        print("WebSocketService: Connecting to \(url.absoluteString)")
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        stopPing()
        print("WebSocketService: Disconnected")
    }
    
    func startStream(userId: String) {
        let payload: [String: Any] = [
            "topic": "audio:\(userId)",
            "event": "start_stream",
            "payload": ["user_id": userId],
            "ref": UUID().uuidString
        ]
        
        sendPhoenixMessage(payload)
    }
    
    func stopStream(userId: String) {
        let payload: [String: Any] = [
            "topic": "audio:\(userId)",
            "event": "stop_stream",
            "payload": [:],
            "ref": UUID().uuidString
        ]
        
        sendPhoenixMessage(payload)
    }
    
    func sendAudioChunk(data: Data, userId: String) {
        // Send as binary frame directly? 
        // AudioChannel expects "audio_chunk" event with "data" payload (base64)
        // because we implemented `handle_in("audio_chunk", ...)`
        
        // Encode data to base64
        let base64Data = data.base64EncodedString()
        
        // 'ref' is optional in Phoenix messages but useful for tracking. 
        // We can just omit it or provide a UUID if needed, but sending 'nil' to [String: Any] is invalid.
        // Let's send a UUID to be consistent.
        let payload: [String: Any] = [
            "topic": "audio:\(userId)",
            "event": "audio_chunk",
            "payload": ["data": base64Data],
            "ref": UUID().uuidString
        ]
        
        sendPhoenixMessage(payload)
    }
    
    // MARK: - Private Methods
    
    private func joinChannel(topic: String, userId: String) {
        // Phoenix V2 JSON Serializer format:
        // [join_ref, ref, topic, event, payload]
        // But usually we send a JSON object if we are not using the phx_serializer?
        // Wait, standard Phoenix channels use a specific protocol.
        // It's safer to use a basic JSON payload that matches standard Phoenix "longpoll" or "websocket" if we parse it manually?
        // Most Phoenix clients allow Object format: 
        // {"topic": "...", "event": "phx_join", "payload": {}, "ref": "..."}
        
        let payload: [String: Any] = [
            "topic": topic,
            "event": "phx_join",
            "payload": [:],
            "ref": UUID().uuidString
        ]
        
        sendPhoenixMessage(payload)
        
        // After joining, start the stream
        // No delay needed - Phoenix channels process sequentially
        self?.startStream(userId: userId)
    }
    
    private func sendPhoenixMessage(_ message: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocketService: Send error: \(error)")
                // Reconnect?
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("WebSocketService: Receive error: \(error)")
                self.disconnect() // Disconnect on error
                
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    print("WebSocketService: Received binary data: \(data.count) bytes")
                @unknown default:
                    break
                }
                
                // Continue receiving
                if self.isConnected {
                    self.receiveMessage()
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Check for specific events
        if let event = json["event"] as? String {
            if event == "transcription_complete" {
                if let payload = json["payload"] as? [String: Any],
                   let transcript = payload["transcript"] as? String {
                    DispatchQueue.main.async {
                        self.onTranscriptionComplete?(transcript)
                    }
                }
            } else if event == "transcript_content" {
                 if let payload = json["payload"] as? [String: Any],
                    let content = payload["content"] as? String {
                     DispatchQueue.main.async {
                         self.onTranscriptMessage?(content)
                     }
                 }
            } else if event == "phx_reply" {
                // Handle reply (e.g., to join or errors)
                 if let payload = json["payload"] as? [String: Any],
                    let status = payload["status"] as? String,
                    status == "error" {
                     print("WebSocketService: Phoenix Error: \(payload)")
                 }
            }
        }
    }
    
    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        let payload: [String: Any] = [
            "topic": "phoenix",
            "event": "heartbeat",
            "payload": [:],
            "ref": UUID().uuidString
        ]
        sendPhoenixMessage(payload)
    }
}
