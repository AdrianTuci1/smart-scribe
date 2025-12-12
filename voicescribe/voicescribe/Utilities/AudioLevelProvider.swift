import Foundation
import AVFoundation
import Combine

class AudioLevelProvider: ObservableObject {
    @Published var audioLevel: Float = 0.0
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?

    init() {
        setupRecorder()
    }
    
    private func setupRecorder() {
        // On macOS, we don't need AVAudioSession for basic recording
        let url = URL(fileURLWithPath: "/dev/null")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
        } catch {
            print("AudioLevelProvider: Failed to setup recorder: \(error)")
        }
    }
    
    func startMonitoring() {
        guard let recorder = audioRecorder else { return }
        
        // Ensure we have permission before starting
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            if recorder.record() {
                startTimer()
            } else {
                print("AudioLevelProvider: Failed to start recording")
            }
        }
    }
    
    func stopMonitoring() {
        audioRecorder?.stop()
        stopTimer()
        self.audioLevel = 0.0
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateLevel()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateLevel() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        
        // normalizedValue is linear 0.0 - 1.0 (approx) from decibels
        // averagePower(forChannel: 0) returns decibels, typically -160 to 0
        let decibels = recorder.averagePower(forChannel: 0)
        let linear = pow(10, (0.05 * decibels))
        
        // Clamp and smooth slightly if needed, but linear is usually fine for a simple bar
        DispatchQueue.main.async {
            self.audioLevel = self.clamp(linear, min: 0.0, max: 1.0)
        }
    }
    
    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        if value < min { return min }
        if value > max { return max }
        return value
    }
}
