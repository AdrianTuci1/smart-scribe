import Foundation

// Test WebSocket connection
let baseURL = "ws://localhost:4000/socket/websocket"
let token = "mock_jwt_token"

// Create URL and request
guard let url = URL(string: baseURL) else {
    print("Invalid URL")
    exit(1)
}

var request = URLRequest(url: url)
if !token.isEmpty {
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}

// Create WebSocket task
let session = URLSession(configuration: .default)
let webSocketTask = session.webSocketTask(with: request)

// Set up message handler
webSocketTask.resume()
webSocketTask.receive { result in
    switch result {
    case .failure(let error):
        print("WebSocket error: \(error)")
    case .success(let message):
        switch message {
        case .string(let text):
            print("Received message: \(text)")
        case .data(let data):
            print("Received binary data: \(data.count) bytes")
        @unknown default:
            break
        }
    }
}

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

// Keep the script running
RunLoop.main.run(until: Date(timeIntervalSinceNow: 10))
