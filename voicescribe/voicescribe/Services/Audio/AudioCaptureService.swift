import AVFoundation
import Combine

class AudioCaptureService: NSObject, ObservableObject {
    static let shared = AudioCaptureService()
    
    // MARK: - Published Properties
    @Published var currentAmplitude: Float = 0.0
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false
    
    // MARK: - Callbacks
    var onAudioChunk: ((Data) -> Void)?
    
    // MARK: - Private Properties
    private let audioEngine = AVAudioEngine()
    private var isRunning = false
    private var converter: AVAudioConverter?
    
    // Target format: 16kHz, Mono, 16-bit Integer PCM (Required for AWS Transcribe)
    private let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!
    
    override private init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start recording from microphone
    func startRecording() throws {
        guard !isRunning else { return }
        
        // Reset states
        DispatchQueue.main.async {
            self.isPaused = false
        }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Initialize converter
        // We need to convert from input format to target format (16kHz PCM)
        converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        
        // Install tap
        // bufferSize is a request, not a guarantee. 100ms at 44.1kHz is ~4410 frames
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        try audioEngine.start()
        isRunning = true
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
        
        print("AudioCapture: Started recording at \(inputFormat.sampleRate)Hz, converting to 16000Hz")
    }
    
    /// Stop recording
    func stopRecording() {
        guard isRunning else { return }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        converter = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.isPaused = false
            self.currentAmplitude = 0.0
        }
        
        print("AudioCapture: Stopped recording")
    }
    
    /// Pause recording
    func pauseRecording() {
        guard isRunning && !isPaused else { return }
        
        audioEngine.pause()
        
        DispatchQueue.main.async {
            self.isPaused = true
            // Keep currentAmplitude as is or reset? Usually helpful to see it drop to 0
             self.currentAmplitude = 0.0
        }
        
        print("AudioCapture: Paused recording")
    }
    
    /// Resume recording
    func resumeRecording() throws {
        guard isRunning && isPaused else { return }
        
        try audioEngine.start()
        
        DispatchQueue.main.async {
            self.isPaused = false
        }
        
        print("AudioCapture: Resumed recording")
    }
    
    /// Check microphone permission using PermissionManager
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        completion(PermissionManager.shared.isMicrophonePermissionGranted())
    }
    
    // MARK: - Private Methods
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Calculate amplitude for visualization (using original input buffer is fine)
        let amplitude = calculateAmplitude(buffer)
        DispatchQueue.main.async {
            // Only update amplitude if not paused (though engine is likely paused)
            if !self.isPaused {
                self.currentAmplitude = amplitude
            }
        }
        
        // If paused, do not send audio chunks
        if isPaused { return }
        
        // Convert audio to 16000 Hz Int16
        guard let converter = converter else { return }
        
        // Calculate output buffer size
        // ratio = 16000 / starting_rate
        let inputSampleRate = buffer.format.sampleRate
        let ratio = 16000.0 / inputSampleRate
        
        let inputFrameCount = buffer.frameLength
        let outputFrameCapacity = AVAudioFrameCount(Double(inputFrameCount) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            print("AudioCapture: Failed to create output buffer")
            return
        }
        
        var error: NSError?
        
        // Input block for converter
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            // We have all data in 'buffer'
            outStatus.pointee = .haveData
            return buffer
        }
        
        // Perform conversion
        let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if status == .error || error != nil {
            print("AudioCapture: Conversion error: \(String(describing: error))")
            return
        }
        
        // Send converted data
        // For Int16, we use int16ChannelData
        if let data = bufferToData(outputBuffer) {
            onAudioChunk?(data)
        }
    }
    
    private func calculateAmplitude(_ buffer: AVAudioPCMBuffer) -> Float {
        // Use the original float buffer for amplitude calculation as it's easier
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        
        let frameLength = Int(buffer.frameLength)
        // Optimization: Don't check every sample, check stride
        let sampleStride = max(1, frameLength / 100)
        var sum: Float = 0
        var count = 0
        
        for i in stride(from: 0, to: frameLength, by: sampleStride) {
            sum += abs(channelData[i])
            count += 1
        }
        
        let average = count > 0 ? sum / Float(count) : 0
        // Normalize to 0-1 range with some amplification
        return min(average * 10, 1.0)
    }
    
    private func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data? {
        // Handle Int16 buffer (which is our target format)
        if buffer.format.commonFormat == .pcmFormatInt16 {
            guard let channelData = buffer.int16ChannelData else { return nil }
            // channelData is UnsafePointer<UnsafeMutablePointer<Int16>>
            // We want the first channel
            let ptr = channelData[0]
            let count = Int(buffer.frameLength) * Int(buffer.format.channelCount) // Should be 1 channel
            let byteCount = count * MemoryLayout<Int16>.size
            return Data(bytes: ptr, count: byteCount)
        }
        // Handle Float32 buffer (fallback if we needed it)
        else if buffer.format.commonFormat == .pcmFormatFloat32 {
             guard let channelData = buffer.floatChannelData else { return nil }
             let ptr = channelData[0]
             let count = Int(buffer.frameLength) * Int(buffer.format.channelCount)
             let byteCount = count * MemoryLayout<Float>.size
             return Data(bytes: ptr, count: byteCount)
        }
        
        return nil
    }
}
