//
//  PermissionManager.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation
import AVFoundation
import Speech
import Combine

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var microphonePermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var speechRecognitionPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var allPermissionsGranted = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
        
        // Update allPermissionsGranted when either permission changes
        Publishers.CombineLatest($microphonePermissionStatus, $speechRecognitionPermissionStatus)
            .map { microphone, speech in
                return microphone == .authorized && speech == .authorized
            }
            .assign(to: \.allPermissionsGranted, on: self)
            .store(in: &cancellables)
    }
    
    func checkMicrophonePermission() {
        microphonePermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    func checkSpeechRecognitionPermission() {
        speechRecognitionPermissionStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphonePermissionStatus = granted ? .authorized : .denied
                completion(granted)
            }
        }
    }
    
    func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechRecognitionPermissionStatus = status
                completion(status == .authorized)
            }
        }
    }
    
    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        requestMicrophonePermission { [weak self] microphoneGranted in
            self?.requestSpeechRecognitionPermission { speechGranted in
                completion(microphoneGranted && speechGranted)
            }
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    func microphonePermissionDescription() -> String {
        switch microphonePermissionStatus {
        case .authorized:
            return "Microphone access granted"
        case .denied:
            return "Microphone access denied. Please enable in Settings."
        case .notDetermined:
            return "Microphone permission not requested yet"
        case .restricted:
            return "Microphone access restricted"
        @unknown default:
            return "Unknown microphone permission status"
        }
    }
    
    func speechRecognitionPermissionDescription() -> String {
        switch speechRecognitionPermissionStatus {
        case .authorized:
            return "Speech recognition access granted"
        case .denied:
            return "Speech recognition access denied. Please enable in Settings."
        case .notDetermined:
            return "Speech recognition permission not requested yet"
        case .restricted:
            return "Speech recognition access restricted"
        @unknown default:
            return "Unknown speech recognition permission status"
        }
    }
}