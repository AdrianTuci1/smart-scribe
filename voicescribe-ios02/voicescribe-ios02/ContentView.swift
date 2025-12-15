//
//  ContentView.swift
//  voicescribe-ios02
//
//  Created by Adrian Tucicovenco on 12.12.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        Group {
            switch appCoordinator.currentRoute {
            case .onboarding:
                OnboardingView()
            case .authentication:
                AuthenticationView()
            case .home:
                HomeView()
            case .transcription:
                TranscriptionView()
            case .history:
                HistoryView()
            case .settings:
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppCoordinator())
}
