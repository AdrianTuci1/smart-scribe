import config from '../config.js';
import { arrayBufferToBase64 } from '../utils/helpers.js';

/**
 * Audio Recording Service using AudioContext for raw PCM access
 * Converts audio to 16kHz mono 16-bit PCM for AWS Transcribe
 */
class AudioRecordingService {
    constructor() {
        this.audioContext = null;
        this.mediaStream = null;
        this.processor = null;
        this.input = null;
        this.isRecording = false;

        // Callbacks
        this.onAudioChunk = null;
        this.onRecordingStart = null;
        this.onRecordingStop = null;
        this.onError = null;

        // Target format for AWS Transcribe
        this.targetSampleRate = config.audio.sampleRate || 16000;
    }

    /**
     * Request microphone permission explicitly
     */
    async requestMicrophonePermission() {
        try {
            console.log('AudioRecordingService: Requesting microphone permission...');
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            // We just want permission, so stop the stream immediately
            stream.getTracks().forEach(track => track.stop());
            console.log('AudioRecordingService: Microphone permission granted');
            return true;
        } catch (error) {
            console.error('AudioRecordingService: Microphone permission denied', error);
            return false;
        }
    }

    /**
     * Start recording audio
     */
    async startRecording() {
        if (this.isRecording) {
            console.warn('AudioRecordingService: Already recording');
            return false;
        }

        try {
            console.log('AudioRecordingService: Requesting microphone access...');
            this.mediaStream = await navigator.mediaDevices.getUserMedia({
                audio: {
                    channelCount: 1, // Mono
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true,
                }
            });

            // Initialize AudioContext
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            this.audioContext = new AudioContext();
            const inputSampleRate = this.audioContext.sampleRate;

            console.log(`AudioRecordingService: AudioContext started at ${inputSampleRate}Hz`);

            // Create media stream source
            this.input = this.audioContext.createMediaStreamSource(this.mediaStream);

            // Create script processor for raw audio access
            // Buffer size: 4096 gives ~92ms latency at 44.1kHz, reasonable for streaming
            const bufferSize = 4096;
            this.processor = this.audioContext.createScriptProcessor(bufferSize, 1, 1);

            this.processor.onaudioprocess = (e) => {
                if (!this.isRecording) return;

                const inputData = e.inputBuffer.getChannelData(0);
                this.processAudio(inputData, inputSampleRate);
            };

            // Connect graph
            this.input.connect(this.processor);
            // Processor must be connected to destination for onaudioprocess to fire
            this.processor.connect(this.audioContext.destination);

            this.isRecording = true;
            console.log(`AudioRecordingService: Recording started. Converting ${inputSampleRate}Hz -> ${this.targetSampleRate}Hz`);

            if (this.onRecordingStart) {
                this.onRecordingStart();
            }

            return true;
        } catch (error) {
            console.error('AudioRecordingService: Failed to start recording', error);
            if (this.onError) {
                this.onError(error.message || 'Failed to start recording');
            }
            return false;
        }
    }

    /**
     * Stop recording audio
     */
    stopRecording() {
        if (!this.isRecording) return;

        this.isRecording = false;

        // Stop media stream tracks (release mic)
        if (this.mediaStream) {
            this.mediaStream.getTracks().forEach(track => track.stop());
            this.mediaStream = null;
        }

        // Disconnect and clean up audio nodes
        if (this.input) {
            this.input.disconnect();
            this.input = null;
        }

        if (this.processor) {
            this.processor.disconnect();
            this.processor.onaudioprocess = null;
            this.processor = null;
        }

        // Close audio context
        if (this.audioContext) {
            this.audioContext.close();
            this.audioContext = null;
        }

        console.log('AudioRecordingService: Recording stopped and resources cleaned up');

        if (this.onRecordingStop) {
            this.onRecordingStop();
        }
    }

    /**
     * Process raw audio buffer: Downsample and convert to PCM
     */
    processAudio(inputData, inputSampleRate) {
        try {
            // 1. Downsample to target sample rate (16kHz)
            const downsampledBuffer = this.downsampleBuffer(inputData, inputSampleRate, this.targetSampleRate);

            // 2. Convert to Int16 PCM
            const pcmBuffer = this.floatTo16BitPCM(downsampledBuffer);

            // 3. Convert to Base64
            const base64Data = arrayBufferToBase64(pcmBuffer.buffer);

            // 4. Send chunk
            if (this.onAudioChunk) {
                this.onAudioChunk(base64Data);
            }
        } catch (error) {
            console.error('AudioRecordingService: Error processing audio chunk', error);
        }
    }

    /**
     * Downsample audio buffer to target sample rate
     * Uses simple linear interpolation/decimation suitable for real-time speech
     */
    downsampleBuffer(buffer, sampleRate, outSampleRate) {
        if (outSampleRate === sampleRate) {
            return buffer;
        }

        if (outSampleRate > sampleRate) {
            // Upsampling not strictly supported/needed for this use case
            return buffer;
        }

        const sampleRateRatio = sampleRate / outSampleRate;
        const newLength = Math.round(buffer.length / sampleRateRatio);
        const result = new Float32Array(newLength);

        let offsetResult = 0;
        let offsetBuffer = 0;

        while (offsetResult < result.length) {
            const nextOffsetBuffer = Math.round((offsetResult + 1) * sampleRateRatio);

            // Average values to prevent aliasing (simple low-pass filter effect)
            let accum = 0;
            let count = 0;

            for (let i = offsetBuffer; i < nextOffsetBuffer && i < buffer.length; i++) {
                accum += buffer[i];
                count++;
            }

            result[offsetResult] = count > 0 ? accum / count : 0;

            offsetResult++;
            offsetBuffer = nextOffsetBuffer;
        }

        return result;
    }

    /**
     * Convert Float32 audio data to Int16 PCM
     */
    floatTo16BitPCM(input) {
        const output = new Int16Array(input.length);
        for (let i = 0; i < input.length; i++) {
            const s = Math.max(-1, Math.min(1, input[i]));
            // Convert to 16-bit PCM (signed integers)
            output[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
        }
        return output;
    }

    /**
     * Cleanup resources
     */
    cleanup() {
        this.stopRecording();
    }

    /**
     * Check permissions (helper)
     */
    async checkPermission() {
        try {
            const result = await navigator.permissions.query({ name: 'microphone' });
            return result.state === 'granted';
        } catch (error) {
            return false;
        }
    }
}

export default new AudioRecordingService();
