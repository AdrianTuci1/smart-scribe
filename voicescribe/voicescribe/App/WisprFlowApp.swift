import SwiftUI

@main
struct WisprFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService.shared
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            let content = hasCompletedOnboarding
                ? AnyView(MainPopoverViewWithoutUserMenu())
                : AnyView(OnboardingView())
            
            content
                .onOpenURL { url in
                    print("SwiftUI onOpenURL received: \(url.absoluteString)")
                    Task {
                        let success = await authService.handleAuthCallback(url: url)
                        if success {
                            print("Authentication handled via onOpenURL")
                        } else {
                            print("Failed to handle auth callback via onOpenURL: \(authService.errorMessage ?? "Unknown error")")
                        }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("Account") {
                if authService.isAuthenticated {
                    Button("Sign Out") {
                        Task {
                            await authService.signOut()
                        }
                    }
                } else {
                    Button("Sign In") {
                        authService.signInWithWebBrowser()
                    }
                }
            }
        }
    }
}
