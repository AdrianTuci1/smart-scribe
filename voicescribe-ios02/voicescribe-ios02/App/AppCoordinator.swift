//
//  AppCoordinator.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAuthenticated = false
    @Published var currentRoute: Route = .onboarding
    
    // Replace with your actual App Group ID (must be created in Apple Developer Portal & Xcode)
    let appGroupName = "group.com.voicescribe.ios"
    
    enum Route {
        case onboarding
        case authentication
        case home
        case transcription
        case history
        case settings
    }
    
    @Published var currentUserId: String?
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // Check if user is authenticated
        // For now, we'll simulate with a simple check
        // In a real app, this would check with AuthService
        isAuthenticated = false // Start with false for onboarding
        currentRoute = isAuthenticated ? .home : .onboarding
        
        if isAuthenticated {
            // Need to retrieve stored ID in real app
            currentUserId = "user-123" 
            WebSocketService.shared.connect()
        }
    }
    
    func navigateTo(_ route: Route) {
        currentRoute = route
    }
    
    func authenticate() {
        isAuthenticated = true
        currentUserId = "user-123" // Mock ID
        saveToSharedDefaults()
        WebSocketService.shared.connect()
        navigateTo(.home)
    }
    
    func continueAsGuest() {
        let guestId = UUID().uuidString
        isAuthenticated = true
        currentUserId = guestId
        saveToSharedDefaults()
        print("Continuing as guest with ID: \(guestId)")
        WebSocketService.shared.connect()
        navigateTo(.home)
    }
    
    private func saveToSharedDefaults() {
        if let defaults = UserDefaults(suiteName: appGroupName) {
            defaults.set(currentUserId, forKey: "currentUserId")
            defaults.synchronize()
            print("Saved userId to shared group: \(appGroupName)")
        } else {
            print("WARNING: Could not access App Group: \(appGroupName). Make sure it is enabled in Capabilities.")
        }
    }
    
    func signOut() {
        isAuthenticated = false
        WebSocketService.shared.disconnect()
        navigateTo(.onboarding)
    }
}