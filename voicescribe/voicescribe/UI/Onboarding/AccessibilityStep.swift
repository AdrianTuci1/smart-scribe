import SwiftUI
import ApplicationServices

struct AccessibilityStep: View {
    var nextAction: () -> Void
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Enable Accessibility")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("VoiceScribe needs accessibility permissions to\ndetect the Fn hotkey and type text for you.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if permissionManager.accessibilityPermissionStatus {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Permission Granted!")
                        .font(.headline)
                }
                .padding()
            } else {
                VStack(spacing: 15) {
                    Button("Open System Settings") {
                        permissionManager.requestAccessibilityPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Instructions:")
                            .fontWeight(.bold)
                        Text("1. Click the button above.")
                        Text("2. Toggle 'VoiceScribe' ON in the list.")
                        Text("3. If it's already ON, try removing it (-) and adding it again.")
                        Text("4. The app will detect the change automatically.")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            Button("Continue") {
                nextAction()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            // Allow continue if granted OR if user wants to skip (but maybe better to enforce?)
            // Usually for accessibility it's critical. Let's keep it disabled.
            .disabled(!permissionManager.accessibilityPermissionStatus)
        }
        .padding(50)
        .onAppear {
            permissionManager.checkPermissionStatuses()
        }
    }
}
