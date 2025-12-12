import SwiftUI

@main
struct WisprFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService = AuthService.shared
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            contentView
                .onOpenURL(perform: handleOpenURL)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        .commands {
            accountCommands
        }
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var contentView: some View {
        if hasCompletedOnboarding {
            MainPopoverViewWithoutUserMenu()
        } else {
            OnboardingView()
        }
    }
    
    private var accountCommands: some Commands {
        CommandMenu("Account") {
            if authService.isAuthenticated {
                Button("Sign Out", action: signOut)
            } else {
                Button("Sign In", action: signIn)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleOpenURL(_ url: URL) {
        print("=== URL OPENED IN WISPRFLOWAPP ===")
        print("Received authentication callback: \(url.absoluteString)")
        print("URL scheme: \(url.scheme ?? "nil")")
        print("URL host: \(url.host ?? "nil")")
        print("URL path: \(url.path)")
        print("URL query: \(url.query ?? "nil")")
        
        // Check if this is an authentication callback
        if url.scheme == "voicescribe" && (url.host == "auth" || url.path.contains("callback")) {
            print("WisprFlowApp: Processing authentication callback")
            
            // Extract components for more detailed logging
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                print("URL components: \(components)")
                print("Query items: \(components.queryItems?.map { "\($0.name)=\($0.value ?? "nil")" } ?? [])")
            }
            
            print("Current auth service state - isAuthenticated: \(authService.isAuthenticated)")
            print("Current auth service state - hasCurrentUser: \(authService.currentUser != nil)")
            print("Current auth service state - hasToken: \(authService.token != nil)")
            print("Current auth service state - isLoading: \(authService.isLoading)")
            print("Current auth service state - errorMessage: \(authService.errorMessage ?? "nil")")
            
            Task { @MainActor in
                print("Starting authentication callback handling...")
                let success = await authService.handleAuthCallback(url: url)
                
                print("Auth callback handling completed with result: \(success)")
                print("Updated auth service state - isAuthenticated: \(authService.isAuthenticated)")
                print("Updated auth service state - hasCurrentUser: \(authService.currentUser != nil)")
                print("Updated auth service state - hasToken: \(authService.token != nil)")
                print("Updated auth service state - isLoading: \(authService.isLoading)")
                print("Updated auth service state - errorMessage: \(authService.errorMessage ?? "nil")")
                
                if success {
                    print("Authentication successfully handled")
                    
                    // Force reload auth state from UserDefaults to ensure synchronization
                    await authService.reloadAuthState()
                    
                    // Update UI if needed
                    if !hasCompletedOnboarding {
                        print("Onboarding not completed, but user is authenticated")
                    }
                } else {
                    handleAuthError("Authentication failed", authService.errorMessage)
                }
                
                print("=== URL HANDLING COMPLETED ===")
            }
        } else {
            print("WisprFlowApp: Not an authentication callback, ignoring URL")
        }
    }
    
    private func signOut() {
        Task { @MainActor in
            authService.signOut()
        }
    }
    
    private func signIn() {
        authService.signInWithWebBrowser()
    }
    
    private func handleAuthError(_ message: String, _ detail: String?) {
        let errorMessage = detail ?? "Unknown error"
        print("\(message): \(errorMessage)")
    }
}
