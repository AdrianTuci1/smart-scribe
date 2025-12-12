//
//  AuthenticationView.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo or title
                Image(systemName: "mic.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                Text(isSignUp ? "Create Account" : "Sign In")
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
                
                // Action button
                Button(isSignUp ? "Sign Up" : "Sign In") {
                    // Handle authentication
                    appCoordinator.authenticate()
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Toggle between sign in and sign up
                Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                    isSignUp.toggle()
                }
                .foregroundColor(.blue)
                .padding(.top)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        appCoordinator.authenticate()
                    }
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppCoordinator())
}