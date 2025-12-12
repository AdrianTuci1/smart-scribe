import SwiftUI
import AVFoundation
import Combine
import AudioToolbox

struct MicrophoneTestView: View {
    @Binding var isCompleted: Bool
    @StateObject private var recordingManager = TestRecordingManager()
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var hasAttemptedRecording = false
    @State private var showSkipAlert = false
    
    // Flow design tokens
    private let designTokens = DesignTokens()
    
    var body: some View {
        VStack(spacing: designTokens.spacing.componentVerticalSpacing) {
            Text("Test Your Microphone")
                .font(designTokens.fonts.mainTitle)
                .foregroundColor(designTokens.colors.primaryTextColor)
                .fontWeight(.bold)
            
            Text("Let's make sure your microphone is working properly for the best transcription experience.")
                .font(designTokens.fonts.subtitle)
                .foregroundColor(designTokens.colors.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            // Microphone Test Section
            VStack(spacing: designTokens.spacing.componentVerticalSpacing) {
                // Waveform Visualization
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(recordingManager.isRecording ? designTokens.colors.primaryButtonBackground : designTokens.colors.systemGray.opacity(0.3))
                            .frame(width: 4, height: recordingManager.amplitudes[index])
                            .animation(.easeInOut(duration: 0.1), value: recordingManager.amplitudes[index])
                    }
                }
                .frame(height: 40)
                .padding()
                
                // Recording State
                VStack(spacing: 8) {
                    if recordingManager.isRecording {
                        HStack {
                            Circle()
                                .fill(designTokens.colors.errorColor)
                                .frame(width: 8, height: 8)
                                .scaleEffect(recordingManager.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recordingManager.isRecording)
                            
                            Text("Recording... Speak now")
                                .font(designTokens.fonts.inputPlaceholder)
                                .fontWeight(.semibold)
                                .foregroundColor(designTokens.colors.errorColor)
                        }
                    } else if !recordingManager.lastTranscription.isEmpty {
                        Text("Great! We heard you:")
                            .font(designTokens.fonts.inputPlaceholder)
                            .fontWeight(.semibold)
                            .foregroundColor(designTokens.colors.successColor)
                        
                        Text(recordingManager.lastTranscription)
                            .font(designTokens.fonts.subtitle)
                            .padding()
                            .background(designTokens.colors.systemGray6.opacity(0.5))
                            .cornerRadius(10)
                            .multilineTextAlignment(.center)
                    } else if hasAttemptedRecording {
                        Text("Try speaking louder or closer to your microphone")
                            .font(designTokens.fonts.subtitle)
                            .foregroundColor(Color.orange)
                    } else {
                        Text("Click the button below and speak into your microphone")
                            .font(designTokens.fonts.subtitle)
                            .foregroundColor(designTokens.colors.secondaryTextColor)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 15) {
                    if recordingManager.isRecording {
                        Button("Stop Recording") {
                            recordingManager.stopRecording()
                            hasAttemptedRecording = true
                        }
                        .buttonStyle(FlowButtonStyle(type: .primary, designTokens: designTokens, color: designTokens.colors.errorColor))
                        
                        Button("Cancel") {
                            recordingManager.cancelRecording()
                        }
                        .buttonStyle(FlowButtonStyle(type: .secondary, designTokens: designTokens))
                    } else {
                        Button(!recordingManager.lastTranscription.isEmpty ? "Try Again" : "Start Recording") {
                            recordingManager.startRecording()
                        }
                        .buttonStyle(FlowButtonStyle(type: .primary, designTokens: designTokens))
                        .disabled(recordingManager.sessionState == TranscriptionSessionState.processing)
                    }
                }
            }
            .padding()
            .background(designTokens.colors.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(designTokens.colors.ssoButtonBorder, lineWidth: 1)
            )
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 15) {
                Button("Skip") {
                    showSkipAlert = true
                }
                .buttonStyle(FlowButtonStyle(type: .secondary, designTokens: designTokens))
                
                Button("Continue") {
                    isCompleted = true
                }
                .buttonStyle(FlowButtonStyle(type: .primary, designTokens: designTokens))
                .disabled(!hasAttemptedRecording || recordingManager.lastTranscription.isEmpty)
            }
        }
        .padding(designTokens.spacing.paddingHorizontal)
        .background(designTokens.colors.backgroundColor)
        .onAppear {
            // Start with a simple amplitude visualization
            recordingManager.initializeForOnboarding()
        }
        .alert("Skip Microphone Test?", isPresented: $showSkipAlert) {
            Button("Skip", role: .destructive) {
                isCompleted = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You can always test your microphone later in Settings. Some features might not work as expected without confirming your microphone works.")
        }
    }
}


// Simplified recording manager for onboarding
@MainActor
class TestRecordingManager: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var amplitudes: [CGFloat] = Array(repeating: 3, count: 7)
    @Published var sessionState: TranscriptionSessionState = .idle
    @Published var lastTranscription: String = ""
    
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var amplitudeTimer: Timer?
    
    func initializeForOnboarding() {
        // Start with a subtle animation to show it's ready
        startIdleAnimation()
    }
    
    func startRecording() {
        // Check microphone permission using PermissionManager
        // Don't request permission again, just check if it's already granted
        if PermissionManager.shared.isMicrophonePermissionGranted() {
            setupAndStartRecording()
        } else {
            print("Microphone permission not granted - should have been handled in onboarding")
            // Optionally, open settings for user to grant permission
            PermissionManager.shared.openMicrophoneSettings()
        }
    }
    
    private func setupAndStartRecording() {
        do {
            inputNode = audioEngine.inputNode
            let format = inputNode?.outputFormat(forBus: 0)
            
            // Install tap on the input node to get audio data
            inputNode?.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }
            
            // Start the audio engine
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.sessionState = TranscriptionSessionState.recording(sessionId: "test")
                self.startAmplitudeMonitoring()
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS amplitude
        var sum: Float = 0.0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frameLength))
        
        // Update amplitudes on main thread
        DispatchQueue.main.async {
            let scaledAmplitude = CGFloat(3 + min(rms * 50, 22)) // Scale and limit amplitude
            self.updateAmplitudes(scaledAmplitude)
        }
    }
    
    private func startAmplitudeMonitoring() {
        stopIdleAnimation()
        
        amplitudeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Simulate some waveform activity even when not processing audio
            DispatchQueue.main.async {
                if self.isRecording {
                    // Small random variations to show activity
                    for i in 0..<self.amplitudes.count {
                        let variation = CGFloat.random(in: -1...1)
                        self.amplitudes[i] = max(3, min(25, self.amplitudes[i] + variation))
                    }
                }
            }
        }
    }
    
    private func updateAmplitudes(_ amplitude: CGFloat) {
        // Shift amplitudes to the left and add new one
        var newAmplitudes = amplitudes
        newAmplitudes.removeFirst()
        newAmplitudes.append(amplitude)
        amplitudes = newAmplitudes
    }
    
    func stopRecording() {
        DispatchQueue.main.async {
            self.isRecording = false
            self.sessionState = TranscriptionSessionState.processing
            
            // Simulate a transcription result
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.lastTranscription = "This is a test of your microphone. Your voice sounds great!"
                self.sessionState = TranscriptionSessionState.completed(text: self.lastTranscription)
                self.resetAmplitudes()
                self.startIdleAnimation()
            }
        }
        
        stopAudioEngine()
        amplitudeTimer?.invalidate()
        amplitudeTimer = nil
    }
    
    func cancelRecording() {
        DispatchQueue.main.async {
            self.isRecording = false
            self.sessionState = TranscriptionSessionState.idle
            self.lastTranscription = ""
            self.resetAmplitudes()
            self.startIdleAnimation()
        }
        
        stopAudioEngine()
        amplitudeTimer?.invalidate()
        amplitudeTimer = nil
    }
    
    private func stopAudioEngine() {
        inputNode?.removeTap(onBus: 0)
        audioEngine.stop()
    }
    
    private func resetAmplitudes() {
        amplitudes = Array(repeating: 3, count: 7)
    }
    
    private func startIdleAnimation() {
        // Subtle animation when idle
        // Use a non-Sendable timer to avoid Swift 6 concurrency issues
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Check if already recording before starting animation
            if self.isRecording { return }
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                // Check if conditions are still met
                Task { @MainActor [weak self] in
                    guard let self = self, !self.isRecording, self.amplitudes.allSatisfy({ $0 <= 3 }) else {
                        return
                    }
                    
                    let index = Int.random(in: 0..<self.amplitudes.count)
                    self.amplitudes[index] = CGFloat.random(in: 3...5)
                }
            }
            
            // Store timer reference if needed for cleanup
            // Note: In Swift 6, we can't store Timer directly as it's not Sendable
            // The timer will be cleaned up when the view is dismissed
        }
    }
    
    private func stopIdleAnimation() {
        // Idle animation is self-managing through the @MainActor task
        // When isRecording changes to true, the animation naturally stops
    }
}

#Preview {
    MicrophoneTestView(isCompleted: .constant(false))
}