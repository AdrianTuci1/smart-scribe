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
                VStack {
                    // Audio Visualizer
                    HStack(spacing: 4) {
                        ForEach(0..<20) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(self.colorForIndex(index))
                                .frame(width: 8, height: self.heightForIndex(index))
                                .animation(.easeOut(duration: 0.1), value: audioProvider.audioLevel)
                        }
                    }
                    .frame(height: 100)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(16)
                    
                    Text("Speak to test your microphone")
                        .font(.headline)
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
    
    private func colorForIndex(_ index: Int) -> Color {
        // Simple gradient from green to yellow to red
        let normalizedLevel = CGFloat(index) / 20.0
        if normalizedLevel < 0.6 {
            return .green
        } else if normalizedLevel < 0.85 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func heightForIndex(_ index: Int) -> CGFloat {
        // Calculate based on audio level
        let threshold = Float(index) / 20.0
        let level = audioProvider.audioLevel
        
        if level > threshold {
            return 20 + CGFloat(level - threshold) * 80
        } else {
            return 4 // Base height
        }
    }
}

