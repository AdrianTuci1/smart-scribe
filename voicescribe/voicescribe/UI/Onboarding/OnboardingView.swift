import SwiftUI
import AVFoundation
import ApplicationServices

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentStep = 0
    @StateObject private var authService = AuthService.shared
    @State private var isProcessingAuth = false
    
    var body: some View {
        VStack {
            if currentStep == 0 {
                WelcomeStep(
                    authService: authService,
                    isProcessingAuth: $isProcessingAuth,
                    nextAction: { currentStep += 1 }
                )
            } else if currentStep == 1 {
                PermissionsStep(nextAction: { currentStep += 1 })
            } else {
                SetupStep(finishAction: { hasCompletedOnboarding = true })
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