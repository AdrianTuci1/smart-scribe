//
//  AuthUser.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation

struct AuthUser: Identifiable, Codable {
    let id: String
    var email: String
    var displayName: String
    var profileImageURL: URL?
    var createdAt: Date
    var lastLoginAt: Date?
    var subscriptionType: SubscriptionType
    var preferences: UserPreferences
    
    enum SubscriptionType: String, CaseIterable, Codable {
        case free = "Free"
        case premium = "Premium"
        case pro = "Pro"
        
        var features: [String] {
            switch self {
            case .free:
                return ["5 hours of transcription per month", "Basic vocabulary"]
            case .premium:
                return ["Unlimited transcription", "Advanced vocabulary", "Sync across devices", "Priority support"]
            case .pro:
                return ["Unlimited transcription", "Advanced vocabulary", "Custom vocabulary", "Sync across devices", "Priority support", "API access"]
            }
        }
    }
    
    struct UserPreferences: Codable {
        var autoTranscription: Bool = true
        var backgroundRecording: Bool = true
        var notificationsEnabled: Bool = true
        var language: String = "en-US"
        var theme: AppTheme = .system
        
        enum AppTheme: String, CaseIterable, Codable {
            case light = "Light"
            case dark = "Dark"
            case system = "System"
        }
    }
    
    init(
        id: String,
        email: String,
        displayName: String,
        profileImageURL: URL? = nil,
        createdAt: Date = Date(),
        lastLoginAt: Date? = nil,
        subscriptionType: SubscriptionType = .free,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.subscriptionType = subscriptionType
        self.preferences = preferences
    }
    
    // Methods
    mutating func updateLastLogin() {
        lastLoginAt = Date()
    }
    
    mutating func updateProfile(displayName: String? = nil, profileImageURL: URL? = nil) {
        if let displayName = displayName {
            self.displayName = displayName
        }
        if let profileImageURL = profileImageURL {
            self.profileImageURL = profileImageURL
        }
    }
    
    mutating func updatePreferences(_ preferences: UserPreferences) {
        self.preferences = preferences
    }
}