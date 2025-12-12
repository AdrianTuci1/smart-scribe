//
//  AudioCaptureService.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation
import AVFoundation
import Combine

class AudioCaptureService: NSObject, ObservableObject {
    static let shared = AudioCaptureService()
    
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var audioEngine: AVAudioEngine?
    private var timer: Timer?
    private var audioFileURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
        setupAudioEngine()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        let inputNode = audioEngine?.inputNode
        let format = inputNode?.outputFormat(forBus: 0)
        
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            let rms = self?.calculateRMS(buffer: buffer) ?? 0.0
            DispatchQueue.main.async {
                self?.audioLevel = rms
            }
        }
    }
    
    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        var rms: Float = 0.0
        let channelData = buffer.floatChannelData![0]
        
        for i in 0..<buffer.frameLength {
            rms += channelData[Int(i)] * channelData[Int(i)]
        }
        
        return sqrt(rms / Float(buffer.frameLength))
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        audioSession.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func startRecording() throws {
        guard !isRecording else { return }
        
        // Create a unique file URL for the recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        audioFileURL = documentsPath.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFileURL!, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        // Start the audio engine for level monitoring
        try audioEngine?.start()
        
        // Start timer for duration tracking
        recordingDuration = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            self.recordingDuration += 0.1
            
            // Update audio levels
            self.audioRecorder?.updateMeters()
            self.audioLevel = self.audioRecorder?.averagePower(forChannel: 0) ?? 0.0
        }
        
        isRecording = true
        
        // Configure for background recording
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP])
        } catch {
            print("Failed to configure background audio: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        timer?.invalidate()
        timer = nil
        
        isRecording = false
        audioLevel = 0.0
        
        // Reset audio session category
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    func pauseRecording() {
        guard isRecording, let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.pause()
        timer?.invalidate()
    }
    
    func resumeRecording() {
        guard isRecording, let recorder = audioRecorder, !recorder.isRecording else { return }
        recorder.record()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            self.recordingDuration += 0.1
        }
    }
    
    func getRecordingURL() -> URL? {
        return audioFileURL
    }
    
    func deleteRecording() {
        guard let url = audioFileURL else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to delete recording: \(error.localizedDescription)")
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}