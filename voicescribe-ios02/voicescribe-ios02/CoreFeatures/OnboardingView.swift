//
//  OnboardingView.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Progress indicator
            HStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top)
            
            Spacer()
            
            // Content based on current step
            switch currentStep {
            case 0:
                OnboardingStep(
                    title: "Welcome to VoiceScribe",
                    description: "Transform your voice into text with powerful AI transcription.",
                    icon: "mic.fill"
                )
            case 1:
                OnboardingStep(
                    title: "Record Anywhere",
                    description: "Capture audio in any app with our extensions and background recording.",
                    icon: "apps.iphone"
                )
            case 2:
                OnboardingStep(
                    title: "Sync & Organize",
                    description: "Access your transcriptions across all devices and keep them organized.",
                    icon: "icloud.fill"
                )
            default:
                EmptyView()
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .foregroundColor(.blue)
                    .padding()
                }
                
                Spacer()
                
                if currentStep < 2 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                } else {
                    Button("Get Started") {
                        appCoordinator.navigateTo(.authentication)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .padding(.bottom)
        }
        .padding()
    }
}

struct OnboardingStep: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppCoordinator())
}