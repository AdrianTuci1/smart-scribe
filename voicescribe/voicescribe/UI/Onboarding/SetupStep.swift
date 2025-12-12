import SwiftUI

struct SetupStep: View {
    var finishAction: () -> Void
    @State private var hotkeyTested = false
    
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
            
            // Hotkey test section
            VStack(spacing: 15) {
                Text("Test Global Hotkey")
                    .font(.headline)
                
                Text(hotkeyTested ? "✅ Hotkey is working!" : "Press Fn key to test if global hotkey is working")
                    .foregroundColor(hotkeyTested ? .green : .secondary)
                
                if !hotkeyTested {
                    Text("Make sure you've granted Accessibility permission for this feature to work.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            Spacer()
            
            Button("Start Using VoiceScribe") {
                finishAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(50)
        .onReceive(NotificationCenter.default.publisher(for: .globalHotkeyPressed)) { _ in
            hotkeyTested = true
        }
    }
}