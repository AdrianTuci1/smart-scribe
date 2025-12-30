import config from '../config';
import { arrayBufferToBase64 } from '../utils/helpers';

/**
 * Audio Recording Service using AudioWorklet for raw PCM access
 * Converts audio to 16kHz mono 16-bit PCM for AWS Transcribe
 */
class AudioRecordingService {
    private audioContext: AudioContext | null = null;
    private mediaStream: MediaStream | null = null;
    private workletNode: AudioWorkletNode | null = null;
    private input: MediaStreamAudioSourceNode | null = null;
    public isRecording: boolean = false;

    // Callbacks
    public onAudioChunk: ((base64Data: string) => void) | null = null;
    public onRecordingStart: (() => void) | null = null;
    public onRecordingStop: (() => void) | null = null;
    public onError: ((errorMsg: string) => void) | null = null;

    // Target format for AWS Transcribe
    private targetSampleRate: number;

    constructor() {
        this.targetSampleRate = config.audio.sampleRate || 16000;
    }

    /**
     * Request microphone permission explicitly
     */
    public async requestMicrophonePermission(): Promise<boolean> {
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
    public async startRecording(): Promise<boolean> {
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
            const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
            this.audioContext = new AudioContextClass();
            const inputSampleRate = this.audioContext.sampleRate;

            console.log(`AudioRecordingService: AudioContext started at ${inputSampleRate}Hz`);

            // Load AudioWorklet
            try {
                // Use standard URL constructor for Vite/Webpack compatibility
                await this.audioContext.audioWorklet.addModule(new URL('../workers/audio-processor.worklet.ts', import.meta.url).href);
            } catch (e) {
                console.error('AudioRecordingService: Failed to load audio worklet', e);
                throw new Error('Failed to load audio processor');
            }

            // Create media stream source
            this.input = this.audioContext.createMediaStreamSource(this.mediaStream);

            // Create AudioWorkletNode
            this.workletNode = new AudioWorkletNode(this.audioContext, 'audio-processor');

            // Handle messages from worklet
            this.workletNode.port.onmessage = (event) => {
                if (!this.isRecording || event.data.event !== 'audio_chunk') return;

                const inputData = event.data.data; // Float32Array
                this.processAudio(inputData, inputSampleRate);
            };

            // Connect graph
            this.input.connect(this.workletNode);
            // Connect to destination to keep the graph alive
            this.workletNode.connect(this.audioContext.destination);

            this.isRecording = true;
            console.log(`AudioRecordingService: Recording started. Converting ${inputSampleRate}Hz -> ${this.targetSampleRate}Hz`);

            if (this.onRecordingStart) {
                this.onRecordingStart();
            }

            return true;
        } catch (error) {
            console.error('AudioRecordingService: Failed to start recording', error);
            const errorMessage = error instanceof Error ? error.message : 'Failed to start recording';
            if (this.onError) {
                this.onError(errorMessage);
            }
            return false;
        }
    }

    /**
     * Stop recording audio
     */
    public stopRecording() {
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

        if (this.workletNode) {
            this.workletNode.disconnect();
            this.workletNode.port.onmessage = null;
            this.workletNode = null;
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
    private processAudio(inputData: Float32Array, inputSampleRate: number) {
        try {
            // 1. Downsample to target sample rate (16kHz)
            const downsampledBuffer = this.downsampleBuffer(inputData, inputSampleRate, this.targetSampleRate);

            // 2. Convert to Int16 PCM
            const pcmBuffer = this.floatTo16BitPCM(downsampledBuffer);

            // 3. Convert to Base64
            // arrayBufferToBase64 expects ArrayBufferLike which typed array .buffer provides
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
    private downsampleBuffer(buffer: Float32Array, sampleRate: number, outSampleRate: number): Float32Array {
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
    private floatTo16BitPCM(input: Float32Array): Int16Array {
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
    public cleanup() {
        this.stopRecording();
    }

    /**
     * Check permissions (helper)
     */
    public async checkPermission(): Promise<boolean> {
        try {
            const result = await navigator.permissions.query({ name: 'microphone' as PermissionName });
            return result.state === 'granted';
        } catch (error) {
            return false;
        }
    }
}

export default new AudioRecordingService();
