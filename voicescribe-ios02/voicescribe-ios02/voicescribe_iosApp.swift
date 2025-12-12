//
//  voicescribe_iosApp.swift
//  voicescribe-ios
//
//  Created by Adrian Tucicovenco on 12.12.2025.
//

import SwiftUI
import Firebase

@main
struct VoiceScribeApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
        }
    }
}