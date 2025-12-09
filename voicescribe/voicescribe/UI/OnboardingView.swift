import SwiftUI
import AVFoundation
import ApplicationServices

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentStep = 0
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        VStack {
            if currentStep == 0 {
                WelcomeStep(authService: authService, nextAction: { currentStep += 1 })
            } else if currentStep == 1 {
                PermissionsStep(nextAction: { currentStep += 1 })
            } else {
                SetupStep(finishAction: { hasCompletedOnboarding = true })
            }
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct WelcomeStep: View {
    @ObservedObject var authService: AuthService
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
                        Button("Sign In with Browser") {
                            authService.signInWithWebBrowser()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
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
            .disabled(!authService.isAuthenticated)
        }
        .padding(50)
    }
}

struct PermissionsStep: View {
    var nextAction: () -> Void
    @State private var isMicrophoneGranted = false
    @State private var isAccessibilityGranted = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("VoiceScribe needs a few permissions to work its magic.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 20) {
                PermissionRow(
                    title: "Microphone",
                    description: "Required to capture your voice.",
                    icon: "mic.fill",
                    isGranted: isMicrophoneGranted,
                    action: requestMicrophoneAccess
                )
                
                PermissionRow(
                    title: "Accessibility (Optional)",
                    description: "Only for global hotkey (Fn key). Can skip for now.",
                    icon: "keyboard.fill",
                    isGranted: isAccessibilityGranted,
                    action: openAccessibilitySettings
                )
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            if !isAccessibilityGranted {
                Text("💡 You can enable Accessibility later in Settings for global hotkey support")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("Continue") {
                nextAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isMicrophoneGranted) // Only microphone is required
        }
        .padding(50)
        .onAppear {
            checkPermissions()
        }
    }
    
    func checkPermissions() {
        // Check Mic
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            isMicrophoneGranted = true
        default:
            isMicrophoneGranted = false
        }
        
        // Check Accessibility
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
    }
    
    func requestMicrophoneAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                self.isMicrophoneGranted = granted
            }
        }
    }
    
    func openAccessibilitySettings() {
        // Open System Settings > Privacy & Security > Accessibility
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        // Start checking if permission was granted
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
            let granted = AXIsProcessTrustedWithOptions(options)
            
            DispatchQueue.main.async {
                if granted {
                    self.isAccessibilityGranted = true
                    timer.invalidate()
                }
            }
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let icon: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct SetupStep: View {
    var finishAction: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
            
            VStack(spacing: 10) {
                Text("All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("You're ready to start using VoiceScribe.")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("💡 Tip: Press Fn key to record anywhere (requires Accessibility)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.accentColor.opacity(0.05))
                .cornerRadius(8)
            
            Spacer()
            
            Button("Start Using VoiceScribe") {
                finishAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(50)
    }
}
