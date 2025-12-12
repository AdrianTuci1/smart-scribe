//
//  SignUpView.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @ObservedObject private var authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty && !displayName.isEmpty && password == confirmPassword && password.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo
            Image(systemName: "mic.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Form fields
            VStack(spacing: 15) {
                TextField("Display Name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Password validation message
            if !password.isEmpty && password.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            } else if !confirmPassword.isEmpty && password != confirmPassword {
                Text("Passwords don't match")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Sign up button
            Button(action: signUp) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign Up")
                }
            }
            .disabled(isLoading || !isValidForm)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isValidForm ? Color.blue : Color.gray)
            .cornerRadius(10)
            .padding(.horizontal)
            
            Spacer()
            
            // Sign in link
            HStack {
                Text("Already have an account?")
                    .font(.caption)
                
                Button("Sign In") {
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
    
    private func signUp() {
        isLoading = true
        
        authService.signUp(email: email, password: password, displayName: displayName) { result in
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
}

#Preview {
    NavigationView {
        SignUpView()
            .environmentObject(AppCoordinator())
    }
}