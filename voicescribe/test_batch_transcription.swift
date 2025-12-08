import Foundation

// Test script for batch transcription flow
// This script tests the new batch transcription API endpoints

// Test data
let userId = "test_user_123"
let testAudioChunk = Data(repeating: 0x41, count: 1024) // Dummy audio data

// API base URL
let baseURL = "http://localhost:4000/api/v1"

// Helper function to make HTTP requests
func makeRequest(url: String, method: String = "GET", body: Data? = nil, headers: [String: String] = [:]) -> Data? {
    guard let url = URL(string: url) else { return nil }
    
    var request = URLRequest(url: url)
    request.httpMethod = method
    
    for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
    }
    
    if let body = body {
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    do {
        let (data, response) = try URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            return data
        } else {
            print("HTTP Error: \(response)")
            return nil
        }
    } catch {
        print("Request Error: \(error)")
        return nil
    }
}

// Test 1: Start transcription session
print("Test 1: Starting transcription session...")
let startData = try? JSONSerialization.data(withJSONObject: ["user_id": userId])
if let responseData = makeRequest(url: "\(baseURL)/transcribe/start", method: "POST", body: startData),
   let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
   let sessionId = json["session_id"] as? String {
    print("✅ Session started with ID: \(sessionId)")
    
    // Test 2: Upload audio chunk
    print("\nTest 2: Uploading audio chunk...")
    let chunkData = try? JSONSerialization.data(withJSONObject: [
        "user_id": userId,
        "chunk": testAudioChunk.base64EncodedString()
    ])
    
    if makeRequest(url: "\(baseURL)/transcribe/chunk", method: "POST", body: chunkData) != nil {
        print("✅ Audio chunk uploaded successfully")
        
        // Test 3: Finish transcription session
        print("\nTest 3: Finishing transcription session...")
        let finishData = try? JSONSerialization.data(withJSONObject: ["user_id": userId])
        
        if makeRequest(url: "\(baseURL)/transcribe/finish", method: "POST", body: finishData) != nil {
            print("✅ Transcription session finished")
            
            // Test 4: Check transcription status
            print("\nTest 4: Checking transcription status...")
            let statusURL = "\(baseURL)/transcribe/status?user_id=\(userId)"
            
            if let statusData = makeRequest(url: statusURL),
               let statusJson = try? JSONSerialization.jsonObject(with: statusData) as? [String: Any],
               let status = statusJson["status"] as? String {
                print("✅ Status check successful: \(status)")
                
                if let session = statusJson["session"] as? [String: Any],
                   let sessionStatus = session["status"] as? String {
                    print("   Session status: \(sessionStatus)")
                    
                    if let result = session["result"] as? String {
                        print("   Transcription result: \(result)")
                    }
                }
            } else {
                print("❌ Failed to check transcription status")
            }
        } else {
            print("❌ Failed to finish transcription session")
        }
    } else {
        print("❌ Failed to upload audio chunk")
    }
} else {
    print("❌ Failed to start transcription session")
}

print("\nBatch transcription flow test completed.")
