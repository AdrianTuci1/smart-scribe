//
//  KeyboardView.swift
//  VoiceScribeKeyboard
//
//  Created on 15.12.2025.
//

import SwiftUI

struct KeyboardView: View {
    @ObservedObject var viewModel: KeyboardViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Error Banner
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            
            // Status
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Main Button
            Button(action: {
                viewModel.toggleRecording()
            }) {
                ZStack {
                    if viewModel.isRecording {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .padding(4)
                            .overlay(
                                PulseEffect()
                            )
                    } else {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            )
                            .shadow(radius: 4)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if !viewModel.isRecording {
                 Text("Hold or Tap to Dictate")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemInputBackground))
    }
}

struct PulseEffect: View {
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(Color.red.opacity(0.4))
            .scaleEffect(animate ? 1.5 : 1.0)
            .opacity(animate ? 0.0 : 1.0)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}
