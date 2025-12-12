import SwiftUI
import AVFoundation
import ApplicationServices

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentStep = 0
    @StateObject private var authService = AuthService.shared
    @State private var isProcessingAuth = false
    
    @State private var selectedDomains: Set<String> = []

    var body: some View {
        VStack {
            if currentStep == 0 {
                WelcomeStep(
                    authService: authService,
                    isProcessingAuth: $isProcessingAuth,
                    nextAction: { currentStep += 1 }
                )
            } else if currentStep == 1 {
                AccessibilityStep(nextAction: { currentStep += 1 })
            } else if currentStep == 2 {
                MicrophoneStep(nextAction: { currentStep += 1 })
            } else if currentStep == 3 {
                DomainSelectionStep(nextAction: { currentStep += 1 }, selectedDomains: $selectedDomains)
            } else if currentStep == 4 {
                DictationTestStep(nextAction: { currentStep += 1 })
            } else {
                SetupStep(finishAction: {
                    completeOnboarding()
                })
            }
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(authService.$isAuthenticated) { isAuthenticated in
            print("OnboardingView: Authentication state changed - isAuthenticated: \(isAuthenticated)")
            if isAuthenticated {
                print("OnboardingView: User is authenticated, current step: \(currentStep)")
                print("OnboardingView: User name: \(authService.userName ?? "nil")")
                print("OnboardingView: User email: \(authService.userEmail ?? "nil")")
                print("OnboardingView: Token available: \(authService.token != nil)")
                
                // Persist authentication state immediately
                persistAuthState()
                
                // Force UI update after a short delay to ensure state is persisted
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isProcessingAuth = false
                    print("OnboardingView: Authentication state should now be persisted")
                }
                
                // Fetch onboarding state from backend (if re-installing)
                checkRemoteOnboardingStatus()
            } else {
                print("OnboardingView: User is not authenticated")
                if let errorMessage = authService.errorMessage {
                    print("OnboardingView: Error message: \(errorMessage)")
                }
                isProcessingAuth = false
            }
        }
        .onAppear {
            print("OnboardingView: View appeared, checking auth status")
            Task {
                await authService.reloadAuthState()
                
                // Check if we already have persisted auth state
                checkPersistedAuthState()
            }
        }
    }
    
    private func completeOnboarding() {
        Task {
            let config = OnboardingConfig(
                hasCompletedOnboarding: true,
                selectedDomains: Array(selectedDomains),
                completedAt: Date()
            )
            do {
                try await APIService.shared.saveOnboardingConfig(config)
                print("Onboarding config saved successfully")
            } catch {
                print("Error saving onboarding config: \(error)")
            }
            
            await MainActor.run {
                hasCompletedOnboarding = true
            }
        }
    }
    
    private func checkRemoteOnboardingStatus() {
        Task {
            do {
                let config = try await APIService.shared.fetchOnboardingConfig()
                if config.hasCompletedOnboarding {
                    print("Remote onboarding confirmed complete. Syncing local state.")
                    await MainActor.run {
                        selectedDomains = Set(config.selectedDomains)
                        // If they completed it, we can skip? 
                        // But maybe we want to let them finish if they entered?
                        // User request: "register that user passed ... so we don't pass him again"
                        // This implies if we detect it, we might set hasCompletedOnboarding = true immediately?
                        // Or maybe just prepopulate data.
                        // Let's set it to true to skip if valid.
                        hasCompletedOnboarding = true
                    }
                }
            } catch {
                print("Error fetching onboarding config: \(error)")
            }
        }
    }
    
    private func persistAuthState() {
        print("OnboardingView: Persisting auth state to UserDefaults")
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(authService.userName, forKey: "userName")
        UserDefaults.standard.set(authService.userEmail, forKey: "userEmail")
        UserDefaults.standard.set(authService.token, forKey: "authToken")
        UserDefaults.standard.set(authService.refreshToken, forKey: "refreshToken")
        
        // Force synchronization
        UserDefaults.standard.synchronize()
        
        print("OnboardingView: Auth state persisted")
        print("OnboardingView: Saved isAuthenticated: \(UserDefaults.standard.bool(forKey: "isAuthenticated"))")
        print("OnboardingView: Saved userName: \(UserDefaults.standard.string(forKey: "userName") ?? "nil")")
        print("OnboardingView: Saved userEmail: \(UserDefaults.standard.string(forKey: "userEmail") ?? "nil")")
    }
    
    private func checkPersistedAuthState() {
        let isAuth = UserDefaults.standard.bool(forKey: "isAuthenticated")
        let userName = UserDefaults.standard.string(forKey: "userName")
        let userEmail = UserDefaults.standard.string(forKey: "userEmail")
        let token = UserDefaults.standard.string(forKey: "authToken")
        
        print("OnboardingView: Checking persisted auth state")
        print("OnboardingView: isAuth: \(isAuth)")
        print("OnboardingView: userName: \(userName ?? "nil")")
        print("OnboardingView: userEmail: \(userEmail ?? "nil")")
        print("OnboardingView: token: \(token != nil ? "YES" : "NO")")
        
        if isAuth && token != nil {
            // Force update auth service from persisted state
            authService.userName = userName
            authService.userEmail = userEmail
            authService.token = token
            authService.isAuthenticated = true
            
            // Update API service token
            if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
                APIService.shared.setAuthToken(accessToken)
            } else if let token = token {
                APIService.shared.setAuthToken(token)
            }
            
            print("OnboardingView: Updated authService from persisted state")
        }
    }
}