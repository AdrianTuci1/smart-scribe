import SwiftUI

@main
struct WisprFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainPopoverView()
            } else {
                OnboardingView()
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // Optional: cleaner look for onboarding
    }
}
