import AVFoundation
import Combine

class AudioCaptureService: NSObject, ObservableObject {
    static let shared = AudioCaptureService()
    
    // MARK: - Published Properties
    @Published var currentAmplitude: Float = 0.0
    @Published var isRecording: Bool = false
    
    // MARK: - Callbacks
    var onAudioChunk: ((Data) -> Void)?
    
    // MARK: - Private Properties
    private let audioEngine = AVAudioEngine()
    private var isRunning = false
    
    override private init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start recording from microphone
    func startRecording() throws {
        guard !isRunning else { return }
        
        let inputNode = audioEngine.inputNode
        
        // Get native format first
        let nativeFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap with native format
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        try audioEngine.start()
        isRunning = true
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
        
        print("AudioCapture: Started recording")
    }
    
    /// Stop recording
    func stopRecording() {
        guard isRunning else { return }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.currentAmplitude = 0.0
        }
        
        print("AudioCapture: Stopped recording")
    }
    
    /// Check microphone permission using PermissionManager
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        completion(PermissionManager.shared.isMicrophonePermissionGranted())
    }
    
    // MARK: - Private Methods
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Calculate amplitude for waveform visualization
        let amplitude = calculateAmplitude(buffer)
        DispatchQueue.main.async {
            self.currentAmplitude = amplitude
        }
        
        // Convert buffer to data and send via callback
        if let data = bufferToData(buffer) {
            onAudioChunk?(data)
        }
    }
    
    private func calculateAmplitude(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameLength)
        // Normalize to 0-1 range with some amplification
        return min(average * 10, 1.0)
    }
    
    private func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data? {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        guard let mData = audioBuffer.mData else { return nil }
        return Data(bytes: mData, count: Int(audioBuffer.mDataByteSize))
    }
}
