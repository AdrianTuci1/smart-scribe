import SwiftUI

@main
struct WisprFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService.shared
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainPopoverViewWithoutUserMenu()
            } else {
                OnboardingView()
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
