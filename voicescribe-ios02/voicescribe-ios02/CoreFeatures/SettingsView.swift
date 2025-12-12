//
//  SettingsView.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var notificationsEnabled = true
    @State private var autoTranscription = true
    @State private var backgroundRecording = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text("user@example.com")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Sign Out") {
                        appCoordinator.signOut()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Recording")) {
                    Toggle("Auto Transcription", isOn: $autoTranscription)
                    Toggle("Background Recording", isOn: $backgroundRecording)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://voicescribe.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://voicescribe.com/terms")!)
                }
            }
            .navigationTitle("Settings")
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
    SettingsView()
        .environmentObject(AppCoordinator())
}