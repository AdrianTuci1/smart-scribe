import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL: URL
    private var authToken: String?
    
    private init() {
        self.baseURL = URL(string: CognitoConfig.apiBaseUrl)!
        
        // Check for saved token on initialization
        if let savedToken = UserDefaults.standard.string(forKey: "authToken") {
            self.authToken = savedToken
        }
    }
    
    // MARK: - Authentication
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
        // Also save to UserDefaults for persistence
        UserDefaults.standard.set(token, forKey: "authToken")
    }
    
    func login(username: String, password: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = [
            "username": username,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func signUp(username: String, email: String, password: String) async throws -> SignUpResponse {
        let url = baseURL.appendingPathComponent("auth/signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let signUpData = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: signUpData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(SignUpResponse.self, from: data)
    }
    
    func confirmSignUp(username: String, confirmationCode: String) async throws -> ConfirmResponse {
        let url = baseURL.appendingPathComponent("auth/confirm")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let confirmData = [
            "username": username,
            "confirmation_code": confirmationCode
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: confirmData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(ConfirmResponse.self, from: data)
    }
    
    func refreshToken(refreshToken: String) async throws -> RefreshResponse {
        let url = baseURL.appendingPathComponent("auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let refreshData = [
            "refresh_token": refreshToken
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: refreshData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(RefreshResponse.self, from: data)
    }
    
    func logout() async throws {
        let url = baseURL.appendingPathComponent("auth/logout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authentication token
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    // MARK: - Cognito OAuth
    
    func exchangeAuthCodeForTokens(code: String) async throws -> CognitoTokenResponse {
        guard let tokenURL = URL(string: "\(CognitoConfig.cognitoDomain)/oauth2/token") else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid token URL"])
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyParams: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": CognitoConfig.clientId,
            "code": code,
            "redirect_uri": CognitoConfig.redirectUri
        ]
        
        // Include client secret when configured
        if !CognitoConfig.clientSecret.isEmpty && CognitoConfig.clientSecret != "your_client_secret" {
            let credentials = "\(CognitoConfig.clientId):\(CognitoConfig.clientSecret)"
            if let credentialData = credentials.data(using: .utf8) {
                let encoded = credentialData.base64EncodedString()
                request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
            } else {
                bodyParams["client_secret"] = CognitoConfig.clientSecret
            }
        }
        
        let allowed = CharacterSet.urlQueryAllowed
        let bodyString = bodyParams
            .map { key, value in
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(key)=\(encodedValue)"
            }
            .joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            let message = String(data: data, encoding: .utf8) ?? "HTTP Error \(httpResponse.statusCode)"
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        return try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
    }
    
    // MARK: - API Methods
    
    private func createRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authentication token if available
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func fetchSnippets() async throws -> [Snippet] {
        let url = baseURL.appendingPathComponent("config/snippets")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode([Snippet].self, from: data)
    }
    
    func saveSnippets(_ snippets: [Snippet]) async throws {
        let url = baseURL.appendingPathComponent("config/snippets/save")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let snippetsData = try JSONEncoder().encode(snippets)
        request.httpBody = snippetsData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    func fetchDictionary() async throws -> [DictionaryEntry] {
        let url = baseURL.appendingPathComponent("config/dictionary")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode([DictionaryEntry].self, from: data)
    }
    
    func saveDictionary(_ dictionary: [DictionaryEntry]) async throws {
        let url = baseURL.appendingPathComponent("config/dictionary/save")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dictionaryData = try JSONEncoder().encode(dictionary)
        request.httpBody = dictionaryData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    func fetchStylePreferences() async throws -> StylePreference {
        let url = baseURL.appendingPathComponent("config/style_preferences")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(StylePreference.self, from: data)
    }
    
    func saveStylePreferences(_ preferences: StylePreference) async throws {
        let url = baseURL.appendingPathComponent("config/style_preferences/save")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let preferencesData = try JSONEncoder().encode(preferences)
        request.httpBody = preferencesData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    func fetchNotes() async throws -> [Note] {
        let url = baseURL.appendingPathComponent("notes")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode([Note].self, from: data)
    }
    
    func createNote(_ note: Note) async throws -> Note {
        let url = baseURL.appendingPathComponent("notes")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let noteData = try JSONEncoder().encode(note)
        request.httpBody = noteData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(Note.self, from: data)
    }
    
    func deleteNote(id: String) async throws {
        let url = baseURL.appendingPathComponent("notes/\(id)")
        let request = createRequest(url: url, method: "DELETE")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    // MARK: - Transcription Methods
    
    func startTranscriptionSession(userId: String) async throws -> StartTranscriptionResponse {
        let url = baseURL.appendingPathComponent("transcribe/start")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData = ["user_id": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(StartTranscriptionResponse.self, from: data)
    }
    
    func uploadTranscriptionChunk(userId: String, chunk: String) async throws {
        let url = baseURL.appendingPathComponent("transcribe/chunk")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData = [
            "user_id": userId,
            "chunk": chunk
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    func finishTranscriptionSession(userId: String) async throws {
        let url = baseURL.appendingPathComponent("transcribe/finish")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData = ["user_id": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    func getTranscriptionStatus(userId: String) async throws -> TranscriptionStatusResponse {
        let url = baseURL.appendingPathComponent("transcribe/status")
        
        // Add user_id as query parameter
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        let finalUrl = components?.url ?? url
        
        let requestWithQuery = createRequest(url: finalUrl, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: requestWithQuery)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(TranscriptionStatusResponse.self, from: data)
    }
    
    // MARK: - Transcript History Methods
    
    func fetchTranscripts() async throws -> [Transcript] {
        let url = baseURL.appendingPathComponent("transcripts")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        let decoded = try JSONDecoder().decode(TranscriptsResponse.self, from: data)
        return decoded.data
    }
    
    func deleteTranscript(id: String) async throws {
        let url = baseURL.appendingPathComponent("transcripts/\(id)")
        let request = createRequest(url: url, method: "DELETE")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    func updateTranscript(_ transcript: Transcript) async throws -> Transcript {
        let url = baseURL.appendingPathComponent("transcripts/\(transcript.id)")
        var request = createRequest(url: url, method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let transcriptData = try JSONEncoder().encode(transcript)
        request.httpBody = transcriptData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(Transcript.self, from: data)
    }
    
    func retryTranscription(transcriptId: String) async throws -> Transcript {
        let url = baseURL.appendingPathComponent("transcripts/\(transcriptId)/retry")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(Transcript.self, from: data)
    }
    
    func getTranscriptAudioURL(transcriptId: String) async throws -> URL {
        let url = baseURL.appendingPathComponent("transcripts/\(transcriptId)/audio")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        let decoded = try JSONDecoder().decode(AudioURLResponse.self, from: data)
        guard let audioURL = URL(string: decoded.url) else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid audio URL"])
        }
        return audioURL
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let success: Bool
    let data: AuthData?
    let error: String?
    
    struct AuthData: Codable {
        let access_token: String
        let id_token: String
        let refresh_token: String
        let expires_in: Int
    }
}

struct SignUpResponse: Codable {
    let success: Bool
    let data: SignUpData?
    let error: String?
    
    struct SignUpData: Codable {
        let user_confirmed: Bool
        let user_sub: String
    }
}

struct ConfirmResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

struct RefreshResponse: Codable {
    let success: Bool
    let data: RefreshData?
    let error: String?
    
    struct RefreshData: Codable {
        let access_token: String
        let id_token: String
        let expires_in: Int
    }
}

struct TranscriptsResponse: Codable {
    let data: [Transcript]
}

struct AudioURLResponse: Codable {
    let url: String
}

struct CognitoTokenResponse: Codable {
    let access_token: String
    let refresh_token: String?
    let id_token: String
    let token_type: String
    let expires_in: Int
}
