import SwiftUI

@main
struct WisprFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainPopoverViewWithoutUserMenu()
            } else {
                OnboardingView()
            }
        }
        .windowResizability(.contentSize)
        .commands {
            // Remove default commands if needed
        }
    }
}
