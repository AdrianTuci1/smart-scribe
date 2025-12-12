//
//  AuthService.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation
import AuthenticationServices
import Combine

class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: AuthUser?
    @Published var isAuthenticated = false
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        // Check if user is already authenticated
        // This would typically check with a secure storage like Keychain
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(AuthUser.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<AuthUser, AuthError>) -> Void) {
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if email.lowercased() == "test@example.com" && password == "password" {
                let user = AuthUser(
                    id: "12345",
                    email: email,
                    displayName: "Test User"
                )
                
                // Save user to secure storage
                if let userData = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(userData, forKey: "currentUser")
                }
                
                self.currentUser = user
                self.isAuthenticated = true
                completion(.success(user))
            } else {
                completion(.failure(.invalidCredentials))
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String, completion: @escaping (Result<AuthUser, AuthError>) -> Void) {
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let user = AuthUser(
                id: UUID().uuidString,
                email: email,
                displayName: displayName
            )
            
            // Save user to secure storage
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
            
            self.currentUser = user
            self.isAuthenticated = true
            completion(.success(user))
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    func signInWithWebAuth(presentationAnchor: ASPresentationAnchor, completion: @escaping (Result<AuthUser, AuthError>) -> Void) {
        // Implementation for OAuth flow with web authentication
        let authSession = ASWebAuthenticationSession(
            url: URL(string: "https://example.com/auth")!,
            callbackURLScheme: "voicescribe"
        ) { callbackURL, error in
            if let error = error {
                completion(.failure(.webAuthFailed(error)))
                return
            }
            
            guard let callbackURL = callbackURL else {
                completion(.failure(.invalidCallback))
                return
            }
            
            // Parse callback URL to extract tokens
            // For demo purposes, we'll just create a user
            let user = AuthUser(
                id: UUID().uuidString,
                email: "user@example.com",
                displayName: "Web Auth User"
            )
            
            DispatchQueue.main.async {
                if let userData = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(userData, forKey: "currentUser")
                }
                
                self.currentUser = user
                self.isAuthenticated = true
                completion(.success(user))
            }
        }
        
        authSession.presentationContextProvider = self
        authSession.start()
    }
}

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError(Error)
    case webAuthFailed(Error)
    case invalidCallback
    case biometricNotAvailable
    case biometricFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .webAuthFailed(let error):
            return "Web authentication failed: \(error.localizedDescription)"
        case .invalidCallback:
            return "Invalid authentication callback"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricFailed(let error):
            return "Biometric authentication failed: \(error.localizedDescription)"
        }
    }
}