import SwiftUI

struct WelcomeStep: View {
    @ObservedObject var authService: AuthService
    @Binding var isProcessingAuth: Bool
    var nextAction: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 10) {
                Text("Welcome to VoiceScribe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Transcribe your thoughts instantly, anywhere.")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Log in to continue")
                    .font(.headline)
                
                if authService.isAuthenticated {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authService.userName ?? "Account")
                                .font(.subheadline)
                            Text(authService.userEmail ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Sign Out") {
                            Task {
                                await authService.signOut()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You need to sign in with your account to finish setup.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if isProcessingAuth {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing authentication...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                        } else {
                            VStack {
                                Button("Sign In with Browser") {
                                    isProcessingAuth = true
                                    authService.signInWithWebBrowser()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                
                                Button("Test URL Scheme") {
                                    // Test if URL scheme is properly registered
                                    let testUrl = URL(string: "voicescribe://auth?code=test_code")!
                                    if NSWorkspace.shared.open(testUrl) {
                                        print("Test URL opened successfully")
                                    } else {
                                        print("Failed to open test URL")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        if let error = authService.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            Button("Get Started") {
                nextAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!authService.isAuthenticated || isProcessingAuth)
        }
        .padding(50)
        .onReceive(authService.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                print("WelcomeStep: User is now authenticated, updating UI")
                // Force a small delay to ensure state is stable
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task {
                        // Ensure auth state is fully synchronized
                        await authService.reloadAuthState()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Check auth state when app becomes active (user returns from browser)
            Task {
                await authService.reloadAuthState()
                print("WelcomeStep: App became active, reloaded auth state")
            }
        }
    }
}