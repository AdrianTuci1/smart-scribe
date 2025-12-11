import Foundation
import Combine
import AppKit
import CryptoKit

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AuthUser?
    @Published var token: String?
    @Published var refreshToken: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userName: String?
    @Published var userEmail: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private var currentCodeVerifier: String?
    
    private init() {
        // Check current authentication status
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(username: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Authenticate directly with Cognito
            let tokens = try await authenticateWithCognito(username: username, password: password)
            
            // Successful authentication
            let userInfo = decodeUserInfo(fromIDToken: tokens.id_token, fallbackUsername: username)
            print("✅ User authenticated successfully: \(userInfo.email)")
            
            // Set token in API service (use access_token for backend authentication)
            token = tokens.access_token
            apiService.setAuthToken(tokens.access_token)
            
            // Save tokens to UserDefaults
            UserDefaults.standard.set(tokens.access_token, forKey: "accessToken")
            UserDefaults.standard.set(tokens.id_token, forKey: "authToken")
            
            let user = AuthUser(userId: userInfo.userId, username: userInfo.displayName, email: userInfo.email)
            currentUser = user
            userName = userInfo.displayName
            userEmail = userInfo.email ?? username
            refreshToken = tokens.refresh_token
            isAuthenticated = true
            isLoading = false
            
            // Save to UserDefaults
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
            UserDefaults.standard.set(username, forKey: "userName")
            UserDefaults.standard.set(userEmail, forKey: "userEmail")
            UserDefaults.standard.set(tokens.access_token, forKey: "accessToken")
            UserDefaults.standard.set(tokens.refresh_token, forKey: "refreshToken")
            UserDefaults.standard.set(tokens.id_token, forKey: "authToken")
            
            return true
        } catch {
            isLoading = false
            errorMessage = "Authentication error: \(error.localizedDescription)"
            return false
        }
    }
    
    func signUp(username: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.signUp(username: username, email: email, password: password)
            
            if response.success {
                // Registration successful
                isLoading = false
                return true
            } else {
                // Registration failed
                isLoading = false
                errorMessage = response.error ?? "Registration failed"
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Network error: \(error.localizedDescription)"
            return false
        }
    }
    
    func confirmSignUp(for username: String, with confirmationCode: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.confirmSignUp(username: username, confirmationCode: confirmationCode)
            
            if response.success {
                // Confirmation successful
                isLoading = false
                return true
            } else {
                // Confirmation failed
                isLoading = false
                errorMessage = response.error ?? "Confirmation failed"
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Network error: \(error.localizedDescription)"
            return false
        }
    }
    
    func signOut() {
        Task {
            // Revoke tokens with Cognito if available
            if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
                await revokeTokenWithCognito(accessToken: accessToken)
            }
            
            // Clear local state
            currentUser = nil
            isAuthenticated = false
            token = nil
            refreshToken = nil
            userName = nil
            userEmail = nil
            errorMessage = nil
            
            // Clear API service token
            apiService.setAuthToken(nil)
            
            // Clear UserDefaults
            UserDefaults.standard.removeObject(forKey: "isAuthenticated")
            UserDefaults.standard.removeObject(forKey: "userName")
            UserDefaults.standard.removeObject(forKey: "userEmail")
            UserDefaults.standard.removeObject(forKey: "accessToken")
            UserDefaults.standard.removeObject(forKey: "refreshToken")
            UserDefaults.standard.removeObject(forKey: "authToken")
            
            // Reset onboarding state to show onboarding view after logout
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
    }
    
    func refreshSession() async -> Bool {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            return false
        }
        
        do {
            // Refresh directly with Cognito
            let tokens = try await refreshWithCognito(refreshToken: refreshToken)
            
            // Token refreshed successfully
            token = tokens.id_token
            apiService.setAuthToken(tokens.id_token)
            UserDefaults.standard.set(tokens.access_token, forKey: "accessToken")
            UserDefaults.standard.set(tokens.id_token, forKey: "authToken")
            UserDefaults.standard.set(tokens.refresh_token, forKey: "refreshToken")
            return true
        } catch {
            errorMessage = "Token refresh error: \(error.localizedDescription)"
            return false
        }
    }
    
    func signInWithWebBrowser() {
        let verifier = PKCE.generateVerifier()
        currentCodeVerifier = verifier
        UserDefaults.standard.set(verifier, forKey: "pkceCodeVerifier")
        
        let challenge = PKCE.challenge(for: verifier)
        print("PKCE verifier generated (length \(verifier.count)), challenge: \(challenge)")
        
        var components = URLComponents(string: "\(CognitoConfig.cognitoDomain)/login")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: CognitoConfig.clientId),
            URLQueryItem(name: "response_type", value: CognitoConfig.responseType),
            URLQueryItem(name: "scope", value: CognitoConfig.scope),
            URLQueryItem(name: "redirect_uri", value: CognitoConfig.redirectUri),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        
        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }
    
    func handleAuthCallback(url: URL) async -> Bool {
        // Extract authorization code from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            errorMessage = "Missing authorization code in callback."
            print("Auth callback missing code: \(url.absoluteString)")
            return false
        }
        
        let verifier = currentCodeVerifier ?? UserDefaults.standard.string(forKey: "pkceCodeVerifier")
        
        guard let codeVerifier = verifier else {
            errorMessage = "Missing PKCE verifier. Please try signing in again."
            print("Auth callback missing verifier for URL: \(url.absoluteString)")
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let tokenResponse = try await apiService.exchangeAuthCodeForTokens(code: code, codeVerifier: codeVerifier)
            print("Token exchange succeeded for auth code.")
            let userInfo = decodeUserInfo(fromIDToken: tokenResponse.id_token, fallbackUsername: userName ?? "User")
            
            currentUser = AuthUser(userId: userInfo.userId, username: userInfo.displayName, email: userInfo.email)
            userName = userInfo.displayName
            userEmail = userInfo.email ?? userName
            token = tokenResponse.id_token
            refreshToken = tokenResponse.refresh_token
            isAuthenticated = true
            isLoading = false
            
            // Set token in API service (use access_token for backend authentication)
            apiService.setAuthToken(tokenResponse.access_token)
            
            UserDefaults.standard.set(tokenResponse.access_token, forKey: "accessToken")
            UserDefaults.standard.set(tokenResponse.id_token, forKey: "authToken")
            UserDefaults.standard.removeObject(forKey: "pkceCodeVerifier")
            currentCodeVerifier = nil
            
            return true
        } catch {
            isLoading = false
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            print("Token exchange failed: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkAuthStatus() async {
        // Check UserDefaults for existing authentication
        let isAuth = UserDefaults.standard.bool(forKey: "isAuthenticated")
        let savedUserName = UserDefaults.standard.string(forKey: "userName")
        let savedUserEmail = UserDefaults.standard.string(forKey: "userEmail")
        let savedToken = UserDefaults.standard.string(forKey: "accessToken")
        let savedIdToken = UserDefaults.standard.string(forKey: "authToken")
        let savedRefreshToken = UserDefaults.standard.string(forKey: "refreshToken")
        
        print("AuthService: Auth status - \(isAuth), Token available - \(savedIdToken != nil)")
        
        if isAuth && savedUserName != nil && savedUserEmail != nil && savedToken != nil {
            let userInfo = decodeUserInfo(fromIDToken: savedIdToken, fallbackUsername: savedUserName ?? "User")
            
            isAuthenticated = true
            userName = userInfo.displayName
            userEmail = userInfo.email ?? savedUserEmail ?? savedUserName
            token = savedIdToken
            refreshToken = savedRefreshToken
            
            // Set token in API service (use access_token for backend authentication)
            apiService.setAuthToken(savedToken)
            
            // Create user object
            currentUser = AuthUser(userId: userInfo.userId, username: userInfo.displayName, email: userInfo.email)
        }
    }
    
    private func handleAuthEvent(_ event: String) {
        // Handle auth events if needed
        print("Auth event: \(event)")
    }
    
    // Authenticate directly with Cognito
    private func authenticateWithCognito(username: String, password: String) async throws -> (access_token: String, id_token: String, refresh_token: String) {
        let url = URL(string: "https://cognito-idp.\(CognitoConfig.region).amazonaws.com/")!
            .appendingPathComponent(CognitoConfig.userPoolId)
            .appendingPathComponent(".well-known/jwks.json")
        
        // For now, we'll use a simpler approach - directly call Cognito's token endpoint
        // This is a temporary implementation - in production you should use AWS SDK
        let tokenURL = URL(string: "https://\(CognitoConfig.userPoolId.split(separator: "_").first!).auth.\(CognitoConfig.region).amazoncognito.com/oauth2/token")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "password",
            "client_id": CognitoConfig.clientId,
            "username": username,
            "password": password
        ]
        
        // Add client secret if available
        if !CognitoConfig.clientSecret.isEmpty && CognitoConfig.clientSecret != "your_client_secret" {
            let credentials = "\(CognitoConfig.clientId):\(CognitoConfig.clientSecret)"
            if let credentialData = credentials.data(using: .utf8) {
                let encoded = credentialData.base64EncodedString()
                request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
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
            throw NSError(domain: "CognitoAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        let tokenResponse = try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
        return (
            access_token: tokenResponse.access_token,
            id_token: tokenResponse.id_token,
            refresh_token: tokenResponse.refresh_token ?? ""
        )
    }
    
    // Revoke token with Cognito
    private func revokeTokenWithCognito(accessToken: String) async {
        let tokenURL = URL(string: "https://\(CognitoConfig.userPoolId.split(separator: "_").first!).auth.\(CognitoConfig.region).amazoncognito.com/oauth2/revoke")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "token": accessToken,
            "client_id": CognitoConfig.clientId
        ]
        
        // Add client secret if available
        if !CognitoConfig.clientSecret.isEmpty && CognitoConfig.clientSecret != "your_client_secret" {
            let credentials = "\(CognitoConfig.clientId):\(CognitoConfig.clientSecret)"
            if let credentialData = credentials.data(using: .utf8) {
                let encoded = credentialData.base64EncodedString()
                request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
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
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 400 {
                    print("Failed to revoke token: HTTP \(httpResponse.statusCode)")
                } else {
                    print("Token revoked successfully")
                }
            }
        } catch {
            print("Error revoking token: \(error.localizedDescription)")
        }
    }
    
    // Refresh tokens directly with Cognito
    private func refreshWithCognito(refreshToken: String) async throws -> (access_token: String, id_token: String, refresh_token: String) {
        let tokenURL = URL(string: "https://\(CognitoConfig.userPoolId.split(separator: "_").first!).auth.\(CognitoConfig.region).amazoncognito.com/oauth2/token")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": CognitoConfig.clientId
        ]
        
        // Add client secret if available
        if !CognitoConfig.clientSecret.isEmpty && CognitoConfig.clientSecret != "your_client_secret" {
            let credentials = "\(CognitoConfig.clientId):\(CognitoConfig.clientSecret)"
            if let credentialData = credentials.data(using: .utf8) {
                let encoded = credentialData.base64EncodedString()
                request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
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
            throw NSError(domain: "CognitoAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        let tokenResponse = try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
        return (
            access_token: tokenResponse.access_token,
            id_token: tokenResponse.id_token,
            refresh_token: tokenResponse.refresh_token ?? refreshToken
        )
    }
}

// MARK: - Auth User Model

struct AuthUser {
    let userId: String
    let username: String
    let email: String?
}

// MARK: - Helpers

private extension AuthService {
    struct AuthUserInfo {
        let userId: String
        let displayName: String
        let email: String?
    }
    
    func decodeUserInfo(fromIDToken idToken: String?, fallbackUsername: String) -> AuthUserInfo {
        guard
            let idToken,
            let payload = decodeJWTPayload(idToken)
        else {
            return AuthUserInfo(userId: fallbackUsername, displayName: fallbackUsername, email: nil)
        }
        
        let email = payload["email"] as? String
        let givenName = payload["given_name"] as? String
        let familyName = payload["family_name"] as? String
        let fullName = [givenName, familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        let nameClaim = payload["name"] as? String
        let preferredUsername = payload["preferred_username"] as? String
        let cognitoUsername = payload["cognito:username"] as? String
        
        // Prioritize explicit name claims, then email, and only then Cognito username/sub
        // Use fallbackUsername as last resort instead of cognitoUsername
        let displayName = [nameClaim,
                           fullName.isEmpty ? nil : fullName,
                           email,
                           preferredUsername,
                           fallbackUsername]
            .compactMap { $0 }
            .first ?? fallbackUsername
        
        let userId = payload["sub"] as? String ?? cognitoUsername ?? preferredUsername ?? fallbackUsername
        
        return AuthUserInfo(userId: userId, displayName: displayName, email: email)
    }
    
    func decodeJWTPayload(_ token: String) -> [String: Any]? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }
        
        var base64 = String(segments[1])
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        
        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

// MARK: - PKCE helpers

private enum PKCE {
    static func generateVerifier(length: Int = 64) -> String {
        let allowed = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let characters = (0..<length).compactMap { _ in allowed.randomElement() }
        return String(characters)
    }
    
    static func challenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hashed = SHA256.hash(data: data)
        return base64URLEncode(Data(hashed))
    }
    
    private static func base64URLEncode(_ data: Data) -> String {
        return data
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

