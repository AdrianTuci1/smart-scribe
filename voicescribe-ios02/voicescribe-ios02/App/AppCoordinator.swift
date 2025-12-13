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
    @Published var currentRoute: Route = .onboarding
    
    enum Route {
        case onboarding
        case authentication
        case home
        case transcription
        case history
        case settings
    }
    
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
            WebSocketService.shared.connect()
        }
    }
    
    func navigateTo(_ route: Route) {
        currentRoute = route
    }
    
    func authenticate() {
        isAuthenticated = true
        WebSocketService.shared.connect()
        navigateTo(.home)
    }
    
    func signOut() {
        isAuthenticated = false
        WebSocketService.shared.disconnect()
        navigateTo(.onboarding)
    }
}