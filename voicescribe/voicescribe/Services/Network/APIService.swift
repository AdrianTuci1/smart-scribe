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
        print("APIService: Token set - \(token != nil ? "YES" : "NO")")
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
    
    func exchangeAuthCodeForTokens(code: String, codeVerifier: String?) async throws -> CognitoTokenResponse {
        guard let tokenURL = URL(string: "\(CognitoConfig.cognitoDomain)/oauth2/token") else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid token URL"])
        }
        
        print("Exchanging auth code at: \(tokenURL.absoluteString)")
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyParams: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": CognitoConfig.clientId,
            "code": code,
            "redirect_uri": CognitoConfig.redirectUri
        ]
        if let codeVerifier {
            bodyParams["code_verifier"] = codeVerifier
        }
        
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
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                let message = String(data: data, encoding: .utf8) ?? "HTTP Error \(httpResponse.statusCode)"
                throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            
            return try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
        } catch {
            if let urlError = error as? URLError {
                let enriched = NSError(
                    domain: "APIService",
                    code: urlError.errorCode,
                    userInfo: [NSLocalizedDescriptionKey: "Network error (\(urlError.code)) for \(tokenURL.host ?? tokenURL.absoluteString)"]
                )
                throw enriched
            }
            throw error
        }
    }
    
    // MARK: - API Methods
    
    private func createRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authentication token if available
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("APIService: Adding auth header for URL: \(url.absoluteString)")
        } else {
            print("APIService: No auth token available for URL: \(url.absoluteString)")
        }
        
        return request
    }
    
    private func handleAPIResponse(_ data: Data, _ response: URLResponse) throws {
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            // Try to extract error message from response body
            var errorMessage = "HTTP Error \(httpResponse.statusCode)"
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error response body: \(responseString)")
                
                // Try to parse error from JSON response
                if let responseData = responseString.data(using: .utf8),
                   let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: responseData) {
                    errorMessage = errorResponse.error ?? errorMessage
                }
            }
            
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
    
    func fetchSnippets() async throws -> [Snippet] {
        let url = baseURL.appendingPathComponent("config/snippets")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error fetching snippets: \(responseString)")
            }
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        // Debug print the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Snippets response: \(responseString)")
        }
        
        // Backend returns {data: ...} wrapper
        let responseWrapper = try JSONDecoder().decode(SnippetsResponse.self, from: data)
        return responseWrapper.data ?? []
    }
    
    func saveSnippets(_ snippets: [Snippet]) async throws {
        let url = baseURL.appendingPathComponent("config/snippets/save")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Backend expects {"snippets": [...]}
        let requestData = ["snippets": snippets]
        let snippetsData = try JSONEncoder().encode(requestData)
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
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error fetching dictionary: \(responseString)")
            }
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        // Debug print the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Dictionary response: \(responseString)")
        }
        
        // Backend returns {data: ...} wrapper
        let responseWrapper = try JSONDecoder().decode(DictionaryResponse.self, from: data)
        return responseWrapper.data ?? []
    }
    
    func saveDictionary(_ dictionary: [DictionaryEntry]) async throws {
        let url = baseURL.appendingPathComponent("config/dictionary/save")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Backend expects {"dictionary": {"entries": [...]}}
        let requestData = ["dictionary": ["entries": dictionary]]
        let dictionaryData = try JSONEncoder().encode(requestData)
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
        
        // Backend returns {data: ...} wrapper
        let responseWrapper = try JSONDecoder().decode(StylePreferencesResponse.self, from: data)
        guard let data = responseWrapper.data else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No style preferences data found"])
        }
        return data
    }
    
    func saveStylePreferences(_ preferences: StylePreference) async throws {
        let url = baseURL.appendingPathComponent("config/style_preferences/save")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Backend expects {"preferences": {"context": "...", "style": "..."}}
        // Convert enums to their raw values
        let requestData = ["preferences": [
            "context": preferences.context.rawValue,
            "style": preferences.style.rawValue
        ]]
        let preferencesData = try JSONEncoder().encode(requestData)
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
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error fetching notes: \(responseString)")
            }
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        // Debug print the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Notes response: \(responseString)")
        }
        
        // Backend returns {data: [...]} wrapper
        let responseWrapper = try JSONDecoder().decode(NotesResponse.self, from: data)
        return responseWrapper.data ?? []
    }
    
    func createNote(_ note: Note) async throws -> Note {
        let url = baseURL.appendingPathComponent("notes")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use helper method to ensure proper date formatting
        let noteDict = note.toBackendDictionary()
        let noteData = try JSONSerialization.data(withJSONObject: noteDict)
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
        
        // Backend expects user_id in body
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
        
        // Backend expects "data" instead of "chunk" and gets user_id from auth token
        let requestData = [
            "data": chunk,
            "session_id": userId // Using userId as session_id for now
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
        
        // Backend gets user_id from auth token, but expects session_id in body
        let requestData = ["session_id": userId] // Using userId as session_id for now
        request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
    }
    
    func getTranscriptionStatus(userId: String) async throws -> TranscriptionStatusResponse {
        let url = baseURL.appendingPathComponent("transcribe/status")
        
        // Backend gets user_id from auth token, no query params needed
        let request = createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
            // Print response details for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error response body: \(responseString)")
            }
            throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
        }
        
        // Debug print the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Transcripts response: \(responseString)")
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

// MARK: - Error Response Model

struct APIErrorResponse: Codable {
    let error: String?
    let message: String?
    let status: String?
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

// Response wrapper models for GET endpoints
struct NotesResponse: Codable {
    let data: [Note]?
}

struct SnippetsResponse: Codable {
    let data: [Snippet]?
}

struct DictionaryResponse: Codable {
    let data: [DictionaryEntry]?
}

struct StylePreferencesResponse: Codable {
    let data: StylePreference?
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
}

// MARK: - User Config Methods

extension APIService {
    // MARK: - User Config Methods
    
    func fetchSettings() async throws -> UserSettings {
        let url = baseURL.appendingPathComponent("config/settings")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle 404/Empty as default settings
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
             return UserSettings()
        }
        
        try handleAPIResponse(data, response)
        
        let responseWrapper = try JSONDecoder().decode(SettingsResponse.self, from: data)
        return responseWrapper.data ?? UserSettings()
    }
    
    func saveSettings(_ settings: UserSettings) async throws {
        let url = baseURL.appendingPathComponent("config/settings")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Backend expects the raw object or wrapped? 
        // Based on other configs, it might just take the body as map.
        // But ConfigController put_config merges params. 
        // Let's send it wrapped in case we want to be safe, or just flat.
        // The DynamoDBRepo.put_config takes "data". 
        // If we send JSON, Phoenix parses it into params.
        // Let's send the struct properties directly as the body.
        let settingsData = try JSONEncoder().encode(settings)
        request.httpBody = settingsData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleAPIResponse(data, response)
    }
    
    func fetchOnboardingConfig() async throws -> OnboardingConfig {
        let url = baseURL.appendingPathComponent("config/onboarding")
        let request = createRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
             return OnboardingConfig()
        }
        
        try handleAPIResponse(data, response)
        
        let responseWrapper = try JSONDecoder().decode(OnboardingConfigResponse.self, from: data)
        return responseWrapper.data ?? OnboardingConfig()
    }
    
    func saveOnboardingConfig(_ config: OnboardingConfig) async throws {
        let url = baseURL.appendingPathComponent("config/onboarding")
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let configData = try JSONEncoder().encode(config)
        request.httpBody = configData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleAPIResponse(data, response)
    }
}




