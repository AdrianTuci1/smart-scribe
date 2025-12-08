import Foundation

// Test full transcription flow
print("Starting transcription flow test...")

let baseURL = "ws://localhost:4000/socket/websocket"
let token = "mock_jwt_token"

print("Creating WebSocket connection to: \(baseURL)")

// Create URL and request
guard let url = URL(string: baseURL) else {
    print("Invalid URL")
    exit(1)
}

var request = URLRequest(url: url)
if !token.isEmpty {
    print("Adding authorization token: \(token)")
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}

// Create WebSocket task
let session = URLSession(configuration: .default)
let webSocketTask = session.webSocketTask(with: request)

print("WebSocket task created, connecting...")

// Set up message handler
webSocketTask.resume()
var isConnected = false

webSocketTask.receive { result in
    switch result {
    case .failure(let error):
        print("WebSocket error: \(error)")
    case .success(let message):
        print("Received message type: \(type(of: message))")
        switch message {
        case .string(let text):
            print("Received text message: \(text)")
            
            // Parse JSON response
            guard let data = text.data(using: .utf8) else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let event = json["event"] as? String ?? ""
                    print("Parsed event: \(event)")
                    
                    switch event {
                    case "phx_reply":
                        if let payload = json["payload"] as? [String: Any],
                           let status = payload["status"] as? String {
                            print("Join status: \(status)")
                            if status == "ok" {
                                isConnected = true
                                print("Connected successfully! Starting transcription...")
                                // Start transcription after successful join
                                startTranscription()
                            }
                        }
                    case "transcription":
                        // Handle the final corrected text
                        if let payload = json["payload"] as? [String: Any],
                           let text = payload["text"] as? String {
                            print("Final transcription received: \(text)")
                            print("SUCCESS: Full transcription flow completed!")
                            exit(0) // Success!
                        }
                    default:
                        print("Unhandled event: \(event)")
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        case .data(let data):
            print("Received binary data: \(data.count) bytes")
        @unknown default:
            print("Unknown message type")
        }
    }
}

print("Sending join message...")

// Send join message after a short delay
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    let joinMessage = """
    {
        "event": "phx_join",
        "topic": "transcription:lobby",
        "payload": {"language": "en"},
        "ref": 1
    }
    """
    
    if let data = joinMessage.data(using: .utf8),
       let string = String(data: data, encoding: .utf8) {
        webSocketTask.send(.string(string)) { error in
            if let error = error {
                print("Send error: \(error)")
            } else {
                print("Join message sent successfully")
            }
        }
    }
}

func startTranscription() {
    guard isConnected else { return }
    
    let startMessage = """
    {
        "event": "start_transcription",
        "topic": "transcription:lobby",
        "payload": {},
        "ref": 2
    }
    """
    
    if let data = startMessage.data(using: .utf8),
       let string = String(data: data, encoding: .utf8) {
        webSocketTask.send(.string(string)) { error in
            if let error = error {
                print("Send error: \(error)")
            } else {
                print("Start transcription message sent")
                
                // Simulate sending audio chunks
                simulateAudioChunks()
            }
        }
    }
}

func simulateAudioChunks() {
    // Simulate sending 3 audio chunks
    for i in 1...3 {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
            let audioChunk = """
            {
                "event": "audio_chunk",
                "topic": "transcription:lobby",
                "payload": {"data": "simulated_audio_chunk_\(i)"},
                "ref": \(i + 2)
            }
            """
            
            if let data = audioChunk.data(using: .utf8),
               let string = String(data: data, encoding: .utf8) {
                webSocketTask.send(.string(string)) { error in
                    if let error = error {
                        print("Send audio chunk error: \(error)")
                    } else {
                        print("Sent audio chunk \(i)")
                    }
                }
            }
        }
    }
    
    // Stop transcription after sending all chunks
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
        stopTranscription()
    }
}

func stopTranscription() {
    guard isConnected else { return }
    
    let stopMessage = """
    {
        "event": "stop_transcription",
        "topic": "transcription:lobby",
        "payload": {},
        "ref": 6
    }
    """
    
    if let data = stopMessage.data(using: .utf8),
       let string = String(data: data, encoding: .utf8) {
        webSocketTask.send(.string(string)) { error in
            if let error = error {
                print("Send stop error: \(error)")
            } else {
                print("Stop transcription message sent")
            }
        }
    }
}

// Keep the script running
RunLoop.main.run(until: Date(timeIntervalSinceNow: 15))
