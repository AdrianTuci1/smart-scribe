import SwiftUI

struct DictationTestStep: View {
    var nextAction: () -> Void
    
    @ObservedObject private var recordingManager = RecordingManager.shared
    @State private var transcribedText: String = ""
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Test Dictation")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Give it a try! Press the microphone button and speak naturally.\nVoiceScribe will transcribe your words.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // Transcription Area
            ScrollView {
                VStack(alignment: .leading) {
                    if transcribedText.isEmpty {
                        Text(isRecording ? "Listening..." : "Your transcription will appear here...")
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        Text(transcribedText)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 120)
            }
            .frame(height: 150)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            
            // Recording Controls
            VStack(spacing: 15) {
                Button(action: {
                    toggleRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 60, height: 60)
                            .shadow(radius: 4)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                if isRecording {
                    Text("Recording...")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("Tap to Record")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Looks Good!") {
                if isRecording {
                    recordingManager.stopRecording()
                }
                nextAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .onReceive(recordingManager.$lastTranscription) { text in
            if !text.isEmpty {
                 // Simple append or replace? The recording manager seems to give "lastTranscription" as the result of the session.
                 // If we want accumulation, we might need to handle it. For this test, replacing is likely fine if it's one session.
                 // However, let's just show what we get.
                 withAnimation {
                     transcribedText = text
                 }
            }
        }
        .onReceive(recordingManager.$isRecording) { recording in
            self.isRecording = recording
        }
        .onDisappear {
            if recordingManager.isRecording {
                recordingManager.stopRecording()
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            recordingManager.stopRecording()
        } else {
            // Clear previous text on new recording? Maybe better UX.
            transcribedText = ""
            recordingManager.startRecording()
        }
    }
}

struct DictationTestStep_Previews: PreviewProvider {
    static var previews: some View {
        DictationTestStep(nextAction: {})
            .frame(width: 600, height: 500)
    }
}
