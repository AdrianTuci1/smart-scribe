//
//  SignInView.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @ObservedObject private var authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo
            Image(systemName: "mic.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            Text("Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Form fields
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Sign in button
            Button(action: signIn) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                }
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Or sign in with
            VStack(spacing: 15) {
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal)
                
                // Sign in with Apple
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: handleAppleSignIn
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal)
                
                // Sign in with web
                Button("Sign in with Web") {
                    signInWithWeb()
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Sign up link
            HStack {
                Text("Don't have an account?")
                    .font(.caption)
                
                Button("Sign Up") {
                    appCoordinator.navigateTo(.authentication)
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
            .padding(.bottom)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signIn() {
        isLoading = true
        
        authService.signIn(email: email, password: password) { result in
            isLoading = false
            
            switch result {
            case .success(_):
                appCoordinator.authenticate()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func signInWithWeb() {
        authService.signInWithWebAuth(presentationAnchor: ASPresentationAnchor()) { result in
            switch result {
            case .success(_):
                appCoordinator.authenticate()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            // Handle Apple Sign In
            let appleIDCredential = authorization.credential as! ASAuthorizationAppleIDCredential
            
            let user = AuthUser(
                id: appleIDCredential.user,
                email: appleIDCredential.email ?? "unknown@example.com",
                displayName: appleIDCredential.fullName?.formatted() ?? "Apple User"
            )
            
            // Save user
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
            
            AuthService.shared.currentUser = user
            AuthService.shared.isAuthenticated = true
            
            appCoordinator.authenticate()
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    NavigationView {
        SignInView()
            .environmentObject(AppCoordinator())
    }
}