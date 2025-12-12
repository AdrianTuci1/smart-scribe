//
//  HomeView.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Home")
                    .font(.largeTitle)
                    .padding()
                
                Button("Start Transcription") {
                    appCoordinator.navigateTo(.transcription)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .navigationTitle("VoiceScribe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("History") {
                            appCoordinator.navigateTo(.history)
                        }
                        Button("Settings") {
                            appCoordinator.navigateTo(.settings)
                        }
                        Button("Sign Out") {
                            appCoordinator.signOut()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppCoordinator())
}