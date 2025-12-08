import Foundation

// Test API connection
let baseURL = "http://localhost:4000/api/v1"
let token = "mock_jwt_token"

// Create request
var request = URLRequest(url: URL(string: "\(baseURL)/config/snippets")!)
request.httpMethod = "GET"
request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

// Perform request
let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("Error: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("Invalid response")
        return
    }
    
    print("Status code: \(httpResponse.statusCode)")
    
    if let data = data, let string = String(data: data, encoding: .utf8) {
        print("Response: \(string)")
    }
}

task.resume()

// Wait for response
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))
