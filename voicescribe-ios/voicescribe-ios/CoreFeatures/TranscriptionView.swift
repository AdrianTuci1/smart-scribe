//
//  TranscriptionView.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI

struct TranscriptionView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var isRecording = false
    @State private var transcriptionText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Waveform visualization placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Text("Waveform Visualization")
                            .foregroundColor(.gray)
                    )
                    .padding()
                
                // Recording button
                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        // Start recording
                    } else {
                        // Stop recording and transcribe
                        transcriptionText = "This is a sample transcription of your audio recording."
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)
                
                // Transcription text
                if !transcriptionText.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Transcription:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            Text(transcriptionText)
                                .padding()
                        }
                        .frame(maxHeight: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        appCoordinator.navigateTo(.home)
                    }
                }
            }
        }
    }
}

#Preview {
    TranscriptionView()
        .environmentObject(AppCoordinator())
}