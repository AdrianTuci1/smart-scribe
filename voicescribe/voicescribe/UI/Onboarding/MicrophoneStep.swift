import SwiftUI
import AVFoundation

struct MicrophoneStep: View {
    var nextAction: () -> Void
    @StateObject private var audioProvider = AudioLevelProvider()
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Enable Microphone")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("We need microphone access to transcribe your voice.\nAudio is only processed when you activate recording.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            
            if permissionManager.microphonePermissionStatus == .authorized {
                VStack(spacing: 20) {
                    // Audio Visualizer
                    HStack(alignment: .center, spacing: 4) {
                        ForEach(0..<10) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.red.opacity(0.7))
                                .frame(width: 6, height: 10 + (CGFloat(audioProvider.audioLevel) * 50 * CGFloat.random(in: 0.5...1.5)))
                                .animation(.easeOut(duration: 0.1), value: audioProvider.audioLevel)
                        }
                    }
                    .frame(height: 60)
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
                    
                    Text("Speak to test your microphone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    audioProvider.startMonitoring()
                }
            } else {
                Button("Request Access") {
                    requestAccess()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
            
            Button("Continue") {
                nextAction()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(permissionManager.microphonePermissionStatus != .authorized)
        }
        .padding(50)
        .onAppear {
            permissionManager.checkPermissionStatuses()
        }
        .onDisappear {
            audioProvider.stopMonitoring()
        }
    }
    
    private func requestAccess() {
        permissionManager.requestMicrophonePermission { granted in
            if granted {
                audioProvider.startMonitoring()
            }
        }
    }
}
