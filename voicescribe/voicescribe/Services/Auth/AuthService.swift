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
    
    private init() {
        // Check current authentication status
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Simple Authentication Methods for macOS
    
    func signIn(username: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Simple authentication simulation for development
        // In production, this would connect to your backend
        if username == "test" && password == "test" {
            // Simulate successful authentication
            let user = AuthUser(userId: "test-user", username: username)
            currentUser = user
            userName = username
            userEmail = "test@example.com"
            token = "mock-jwt-token"
            isAuthenticated = true
            isLoading = false
            
            // Save to UserDefaults
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
            UserDefaults.standard.set(username, forKey: "userName")
            UserDefaults.standard.set("test@example.com", forKey: "userEmail")
            UserDefaults.standard.set("mock-jwt-token", forKey: "authToken")
            
            return true
        } else {
            // Simulate failed authentication
            isLoading = false
            errorMessage = "Invalid username or password"
            return false
        }
    }
    
    func signUp(username: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Simple registration simulation for development
        // In production, this would connect to your backend
        let user = AuthUser(userId: UUID().uuidString, username: username)
        currentUser = user
        userName = username
        userEmail = email
        token = "mock-jwt-token"
        isAuthenticated = true
        isLoading = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(username, forKey: "userName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set("mock-jwt-token", forKey: "authToken")
        
        return true
    }
    
    func confirmSignUp(for username: String, with confirmationCode: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Simple confirmation simulation for development
        // In production, this would connect to your backend
        let user = AuthUser(userId: UUID().uuidString, username: username)
        currentUser = user
        userName = username
        userEmail = "confirmed@example.com"
        token = "mock-jwt-token"
        isAuthenticated = true
        isLoading = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(username, forKey: "userName")
        UserDefaults.standard.set("confirmed@example.com", forKey: "userEmail")
        UserDefaults.standard.set("mock-jwt-token", forKey: "authToken")
        
        return true
    }
    
    func signOut() async {
        // Clear authentication state
        currentUser = nil
        userName = nil
        userEmail = nil
        token = nil
        isAuthenticated = false
        errorMessage = nil
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    func refreshSession() async -> Bool {
        // Simple refresh simulation for development
        // In production, this would refresh the token with your backend
        if isAuthenticated {
            token = "refreshed-mock-jwt-token"
            UserDefaults.standard.set("refreshed-mock-jwt-token", forKey: "authToken")
            return true
        }
        return false
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

