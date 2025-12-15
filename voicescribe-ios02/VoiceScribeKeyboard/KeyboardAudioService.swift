//
//  KeyboardAudioService.swift
//  VoiceScribeKeyboard
//
//  Created on 15.12.2025.
//

import Foundation
import AVFoundation

class KeyboardAudioService: NSObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    // Process audio in chunks
    func startRecording(onAudioChunk: @escaping (Data) -> Void) throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.mixWithOthers, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        
        guard let format = recordingFormat else { return }
        
        // Tap the microphone input
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, time) in
            let audioData = self.toData(buffer: buffer)
            onAudioChunk(audioData)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopRecording() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func toData(buffer: AVAudioPCMBuffer) -> Data {
        let channelCount = 1
        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: channelCount)
        var data = Data()
        
        if let channel = channels.first {
            let bufferPointer = UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength))
            data = Data(buffer: bufferPointer)
        }
        
        return data
    }
}
