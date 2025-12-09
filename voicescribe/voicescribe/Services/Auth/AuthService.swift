import Foundation
import Combine
import AppKit

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
            let response = try await apiService.login(username: username, password: password)
            
            if response.success, let authData = response.data {
                // Successful authentication
                let userInfo = decodeUserInfo(fromIDToken: authData.id_token, fallbackUsername: username)
                
                let user = AuthUser(userId: userInfo.userId, username: userInfo.displayName, email: userInfo.email)
                currentUser = user
                userName = userInfo.displayName
                userEmail = userInfo.email ?? username
                token = authData.access_token
                refreshToken = authData.refresh_token
                isAuthenticated = true
                isLoading = false
                
                // Set token in API service
                apiService.setAuthToken(authData.access_token)
                
                // Save to UserDefaults
                UserDefaults.standard.set(true, forKey: "isAuthenticated")
                UserDefaults.standard.set(username, forKey: "userName")
                UserDefaults.standard.set(userEmail, forKey: "userEmail")
                UserDefaults.standard.set(authData.access_token, forKey: "authToken")
                UserDefaults.standard.set(authData.refresh_token, forKey: "refreshToken")
                UserDefaults.standard.set(authData.id_token, forKey: "idToken")
                
                return true
            } else {
                // Failed authentication
                isLoading = false
                errorMessage = response.error ?? "Authentication failed"
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Network error: \(error.localizedDescription)"
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
    
    func signOut() async {
        // Call logout API if authenticated
        if isAuthenticated {
            do {
                try await apiService.logout()
            } catch {
                print("Error during logout: \(error)")
            }
        }
        
        // Clear authentication state
        currentUser = nil
        userName = nil
        userEmail = nil
        token = nil
        refreshToken = nil
        isAuthenticated = false
        errorMessage = nil
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
        // Clear token in API service
        apiService.setAuthToken(nil)
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "idToken")
    }
    
    func refreshSession() async -> Bool {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            return false
        }
        
        do {
            let response = try await apiService.refreshToken(refreshToken: refreshToken)
            
            if response.success, let authData = response.data {
                // Token refreshed successfully
                token = authData.access_token
                apiService.setAuthToken(authData.access_token)
                UserDefaults.standard.set(authData.access_token, forKey: "authToken")
                UserDefaults.standard.set(authData.id_token, forKey: "idToken")
                return true
            } else {
                // Refresh failed
                errorMessage = response.error ?? "Token refresh failed"
                return false
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            return false
        }
    }
    
    func signInWithWebBrowser() {
        var components = URLComponents(string: "\(CognitoConfig.cognitoDomain)/login")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: CognitoConfig.clientId),
            URLQueryItem(name: "response_type", value: CognitoConfig.responseType),
            URLQueryItem(name: "scope", value: CognitoConfig.scope),
            URLQueryItem(name: "redirect_uri", value: CognitoConfig.redirectUri)
        ]
        
        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }
    
    func handleAuthCallback(url: URL) async -> Bool {
        // Extract authorization code from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let tokenResponse = try await apiService.exchangeAuthCodeForTokens(code: code)
            let userInfo = decodeUserInfo(fromIDToken: tokenResponse.id_token, fallbackUsername: userName ?? "User")
            
            currentUser = AuthUser(userId: userInfo.userId, username: userInfo.displayName, email: userInfo.email)
            userName = userInfo.displayName
            userEmail = userInfo.email ?? userName
            token = tokenResponse.access_token
            refreshToken = tokenResponse.refresh_token
            isAuthenticated = true
            isLoading = false
            
            apiService.setAuthToken(tokenResponse.access_token)
            
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
            UserDefaults.standard.set(userName, forKey: "userName")
            UserDefaults.standard.set(userEmail, forKey: "userEmail")
            UserDefaults.standard.set(tokenResponse.access_token, forKey: "authToken")
            UserDefaults.standard.set(tokenResponse.refresh_token, forKey: "refreshToken")
            UserDefaults.standard.set(tokenResponse.id_token, forKey: "idToken")
            
            return true
        } catch {
            isLoading = false
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            return false
        }
    }
    
    private func checkAuthStatus() async {
        // Check UserDefaults for existing authentication
        let isAuth = UserDefaults.standard.bool(forKey: "isAuthenticated")
        let savedUserName = UserDefaults.standard.string(forKey: "userName")
        let savedUserEmail = UserDefaults.standard.string(forKey: "userEmail")
        let savedToken = UserDefaults.standard.string(forKey: "authToken")
        let savedIdToken = UserDefaults.standard.string(forKey: "idToken")
        let savedRefreshToken = UserDefaults.standard.string(forKey: "refreshToken")
        
        if isAuth && savedUserName != nil && savedUserEmail != nil && savedToken != nil {
            let userInfo = decodeUserInfo(fromIDToken: savedIdToken, fallbackUsername: savedUserName ?? "User")
            
            isAuthenticated = true
            userName = userInfo.displayName
            userEmail = userInfo.email ?? savedUserEmail ?? savedUserName
            token = savedToken
            refreshToken = savedRefreshToken
            
            // Set token in API service
            apiService.setAuthToken(savedToken)
            
            // Create user object
            currentUser = AuthUser(userId: userInfo.userId, username: userInfo.displayName, email: userInfo.email)
        }
    }
    
    private func handleAuthEvent(_ event: String) {
        // Handle auth events if needed
        print("Auth event: \(event)")
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
        let preferredUsername = payload["name"] as? String ?? payload["cognito:username"] as? String ?? email ?? fallbackUsername
        let userId = payload["sub"] as? String ?? preferredUsername
        
        return AuthUserInfo(userId: userId, displayName: preferredUsername, email: email)
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

