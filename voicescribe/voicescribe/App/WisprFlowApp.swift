import SwiftUI

@main
struct WisprFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService = AuthService.shared
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        Window("VoiceScribe", id: "main") {
            contentView
                .onOpenURL(perform: handleOpenURL)
                .onAppear {
                    // Initial sizing with a slight delay to ensure window is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        adjustWindowSize(isMainApp: hasCompletedOnboarding)
                    }
                }
                .onChange(of: hasCompletedOnboarding) { _, newValue in
                    adjustWindowSize(isMainApp: newValue)
                }
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
    
    // MARK: - Window Management
    
    private func adjustWindowSize(isMainApp: Bool) {
        guard let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) ?? NSApplication.shared.windows.first else {
            return
        }
        
        if isMainApp {
            // Main App: occupy almost full screen (respecting dock/menu) with padding
            if let screen = window.screen {
                let visibleFrame = screen.visibleFrame
                let padding: CGFloat = 20
                
                let newFrame = NSRect(
                    x: visibleFrame.origin.x + padding,
                    y: visibleFrame.origin.y + padding,
                    width: visibleFrame.width - (padding * 2),
                    height: visibleFrame.height - (padding * 2)
                )
                
                window.setFrame(newFrame, display: true, animate: true)
                window.minSize = NSSize(width: 800, height: 600)
                window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            }
        } else {
            // Onboarding: Smaller wide format (1100x650) & centered
            let width: CGFloat = 1100
            let height: CGFloat = 650
            
            // Calculate center position
            if let screen = window.screen {
                let screenRect = screen.visibleFrame
                let newOriginX = screenRect.origin.x + (screenRect.width - width) / 2
                let newOriginY = screenRect.origin.y + (screenRect.height - height) / 2
                
                window.setFrame(NSRect(x: newOriginX, y: newOriginY, width: width, height: height), display: true, animate: true)
            } else {
                window.setContentSize(NSSize(width: width, height: height))
                window.center()
            }
            
            // Fixed size for onboarding
            window.minSize = NSSize(width: width, height: height)
            window.maxSize = NSSize(width: width, height: height)
        }
    }
}
