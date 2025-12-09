import Foundation
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AuthUser?
    @Published var token: String?
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
                let user = AuthUser(userId: authData.id_token, username: username)
                currentUser = user
                userName = username
                userEmail = "\(username)@example.com" // Extract from response if available
                token = authData.access_token
                isAuthenticated = true
                isLoading = false
                
                // Set token in API service
                apiService.setAuthToken(authData.access_token)
                
                // Save to UserDefaults
                UserDefaults.standard.set(true, forKey: "isAuthenticated")
                UserDefaults.standard.set(username, forKey: "userName")
                UserDefaults.standard.set("\(username)@example.com", forKey: "userEmail")
                UserDefaults.standard.set(authData.access_token, forKey: "authToken")
                
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
        isAuthenticated = false
        errorMessage = nil
        
        // Clear token in API service
        apiService.setAuthToken(nil)
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "authToken")
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
    
    func handleAuthCallback(url: URL) async -> Bool {
        // Extract authorization code from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return false
        }
        
        // For development, simulate successful authentication
        if code == "success" {
            let user = AuthUser(userId: "callback-user", username: "Callback User")
            currentUser = user
            userName = "Callback User"
            userEmail = "callback@example.com"
            token = "callback-jwt-token"
            isAuthenticated = true
            isLoading = false
            
            // Set token in API service
            apiService.setAuthToken("callback-jwt-token")
            
            // Save to UserDefaults
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
            UserDefaults.standard.set("Callback User", forKey: "userName")
            UserDefaults.standard.set("callback@example.com", forKey: "userEmail")
            UserDefaults.standard.set("callback-jwt-token", forKey: "authToken")
            
            return true
        }
        
        return false
    }
    
    private func checkAuthStatus() async {
        // Check UserDefaults for existing authentication
        let isAuth = UserDefaults.standard.bool(forKey: "isAuthenticated")
        let savedUserName = UserDefaults.standard.string(forKey: "userName")
        let savedUserEmail = UserDefaults.standard.string(forKey: "userEmail")
        let savedToken = UserDefaults.standard.string(forKey: "authToken")
        
        if isAuth && savedUserName != nil && savedUserEmail != nil && savedToken != nil {
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.userName = savedUserName
                self.userEmail = savedUserEmail
                self.token = savedToken
                
                // Set token in API service
                self.apiService.setAuthToken(savedToken)
                
                // Create user object
                self.currentUser = AuthUser(userId: "saved-user", username: savedUserName!)
            }
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
}

