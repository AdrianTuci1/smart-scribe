import SwiftUI
import AVFoundation
import ApplicationServices

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
                    title: "Accessibility (Required)",
                    description: "Required for global hotkey (Fn key) to work properly.",
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
            .disabled(!isMicrophoneGranted) // Microphone is required, accessibility is optional for now
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