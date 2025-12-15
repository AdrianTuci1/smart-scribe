//
//  voicescribe_iosApp.swift
//  voicescribe-ios
//
//  Created by Adrian Tucicovenco on 12.12.2025.
//

import SwiftUI


@main
struct VoiceScribeApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    init() {
        // Firebase removed
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
        }
    }
}