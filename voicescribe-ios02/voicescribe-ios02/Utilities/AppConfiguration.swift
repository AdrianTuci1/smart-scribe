//
//  AppConfiguration.swift
//  VoiceScribe
//
//  Created on 13.12.2025.
//

import Foundation

enum AppConfiguration {
    static let baseURL = URL(string: "http://localhost:4000/api")!
    static let websocketURL = URL(string: "ws://localhost:4000/socket/websocket")!
    
    // Helper to constructing full URLs
    static func url(for endpoint: String) -> URL {
        return baseURL.appendingPathComponent(endpoint)
    }
}
