//
//  RecordingManager.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation
import Combine
import AVFoundation

class RecordingManager: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var audioLevel: Float = 0.0
    @Published var currentRecording: Recording?
    @Published var errorMessage: String?
    
    private let audioCaptureService = AudioCaptureService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Bind to audio capture service properties
        audioCaptureService.$isRecording
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        audioCaptureService.$audioLevel
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)
        
        audioCaptureService.$recordingDuration
            .assign(to: \.recordingDuration, on: self)
            .store(in: &cancellables)
    }
    
    func startRecording() {
        // Request microphone permission if needed
        audioCaptureService.requestMicrophonePermission { [weak self] granted in
            if granted {
                do {
                    try self?.audioCaptureService.startRecording()
                    
                    // Create a new recording object
                    self?.currentRecording = Recording(
                        id: UUID(),
                        fileURL: self?.audioCaptureService.getRecordingURL(),
                        date: Date(),
                        duration: 0.0,
                        title: "New Recording"
                    )
                } catch {
                    self?.errorMessage = "Failed to start recording: \(error.localizedDescription)"
                }
            } else {
                self?.errorMessage = "Microphone permission denied"
            }
        }
    }
    
    func stopRecording() {
        audioCaptureService.stopRecording()
        
        // Update the recording duration
        currentRecording?.duration = recordingDuration
        currentRecording?.fileURL = audioCaptureService.getRecordingURL()
        
        isPaused = false
    }
    
    func pauseRecording() {
        audioCaptureService.pauseRecording()
        isPaused = true
    }
    
    func resumeRecording() {
        audioCaptureService.resumeRecording()
        isPaused = false
    }
    
    func deleteCurrentRecording() {
        audioCaptureService.deleteRecording()
        currentRecording = nil
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        return audioCaptureService.formatDuration(duration)
    }
    
    func clearError() {
        errorMessage = nil
    }
}

class Recording: Identifiable, Codable {
    let id: UUID
    var fileURL: URL?
    let date: Date
    var duration: TimeInterval
    var title: String
    var transcription: String?
    
    init(id: UUID, fileURL: URL?, date: Date, duration: TimeInterval, title: String) {
        self.id = id
        self.fileURL = fileURL
        self.date = date
        self.duration = duration
        self.title = title
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, duration, title, transcription
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        title = try container.decode(String.self, forKey: .title)
        transcription = try container.decodeIfPresent(String.self, forKey: .transcription)
        
        // fileURL can't be encoded/decoded directly
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(id.uuidString).m4a"
        fileURL = documentsPath.appendingPathComponent(fileName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(duration, forKey: .duration)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(transcription, forKey: .transcription)
        // fileURL is not encoded
    }
}