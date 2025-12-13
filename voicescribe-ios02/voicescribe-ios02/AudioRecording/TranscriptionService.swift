//
//  TranscriptionService.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import Foundation
import Speech
import Combine
import AVFoundation

class TranscriptionService: NSObject, ObservableObject {
    static let shared = TranscriptionService()
    
    @Published var isTranscribing = false
    @Published var transcriptionResult: TranscriptionResult?
    @Published var errorMessage: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
    }
    
    func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    func startRealTimeTranscription(completion: @escaping (String) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognizer not available"
            return
        }
        
        // Stop the previous task if it's running
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isTranscribing = true
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    completion(result.bestTranscription.formattedString)
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isTranscribing = false
                }
            }
        }
    }
    
    func stopRealTimeTranscription() {
        audioEngine.stop()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }
    
    func transcribeAudioFile(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if the file exists and is accessible
        guard FileManager.default.fileExists(atPath: url.path) else {
            completion(.failure(TranscriptionError.fileNotFound))
            return
        }
        
        isTranscribing = true
        
        // Create a new recognition request
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            isTranscribing = false
            completion(.failure(TranscriptionError.recognizerUnavailable))
            return
        }
        
        // Perform the recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            DispatchQueue.main.async {
                self.isTranscribing = false
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let result = result else {
                    completion(.failure(TranscriptionError.noResult))
                    return
                }
                
                completion(.success(result.bestTranscription.formattedString))
                
                // Save the result
                let transcriptionResult = TranscriptionResult(
                    id: UUID(),
                    text: result.bestTranscription.formattedString,
                    confidence: result.bestTranscription.averageConfidenceScore,
                    date: Date()
                )
                
                self.transcriptionResult = transcriptionResult
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func formatConfidence(_ confidence: Float) -> String {
        return String(format: "%.0f%%", confidence * 100)
    }
    
    // MARK: - Streaming
    
    func startStreaming(topic: String = "transcription:live") {
        // Connect and join channel
        WebSocketService.shared.connect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WebSocketService.shared.joinChannel(topic: topic)
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!
        
        // Converter
        guard let converter = AVAudioConverter(from: recordingFormat, to: targetFormat) else {
            errorMessage = "Could not create audio converter"
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            let targetFrameCapacity = AVAudioFrameCount(targetFormat.sampleRate * Double(buffer.frameLength) / recordingFormat.sampleRate)
            if let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: targetFrameCapacity) {
                var error: NSError?
                converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
                
                if let data = self.toData(buffer: convertedBuffer) {
                    WebSocketService.shared.sendAudioData(data, topic: topic)
                }
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isTranscribing = true
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
        }
    }
    
    func stopStreaming(topic: String = "transcription:live") {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        WebSocketService.shared.leaveChannel(topic: topic)
        // WebSocketService.shared.disconnect() // Keep connected for other features if needed
        
        isTranscribing = false
    }
    
    private func toData(buffer: AVAudioPCMBuffer) -> Data? {
        let channelCount = 1 // Mono
        let channels = UnsafeBufferPointer(start: buffer.int16ChannelData, count: channelCount)
        guard let ch0Data = channels.first else { return nil }
        let totalFrameCount = Int(buffer.frameLength)
        return Data(bytes: ch0Data, count: totalFrameCount * MemoryLayout<Int16>.size)
    }
}

enum TranscriptionError: Error, LocalizedError {
    case fileNotFound
    case recognizerUnavailable
    case noResult
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file not found"
        case .recognizerUnavailable:
            return "Speech recognizer is not available"
        case .noResult:
            return "No transcription result available"
        case .permissionDenied:
            return "Speech recognition permission denied"
        }
    }
}

struct TranscriptionResult: Identifiable, Codable {
    let id: UUID
    let text: String
    let confidence: Float
    let date: Date
}