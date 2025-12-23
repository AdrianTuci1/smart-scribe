import config from '../config.js';
import { arrayBufferToBase64 } from '../utils/helpers.js';

/**
 * Audio Recording Service using MediaRecorder API
 * Handles microphone permissions, recording, and audio chunk processing
 */
class AudioRecordingService {
    constructor() {
        this.mediaRecorder = null;
        this.audioStream = null;
        this.isRecording = false;

        // Callbacks
        this.onAudioChunk = null;
        this.onRecordingStart = null;
        this.onRecordingStop = null;
        this.onError = null;
    }

    /**
     * Request microphone permission and get audio stream
     */
    async requestMicrophonePermission() {
        try {
            console.log('AudioRecordingService: Requesting microphone permission');

            const stream = await navigator.mediaDevices.getUserMedia({
                audio: {
                    channelCount: 1, // Mono audio
                    sampleRate: config.audio.sampleRate,
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true,
                }
            });

            this.audioStream = stream;
            console.log('AudioRecordingService: Microphone permission granted');
            return true;
        } catch (error) {
            console.error('AudioRecordingService: Microphone permission denied', error);
            if (this.onError) {
                this.onError('Microphone permission denied. Please allow microphone access to use transcription.');
            }
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

        // Request permission if we don't have a stream yet
        if (!this.audioStream) {
            const granted = await this.requestMicrophonePermission();
            if (!granted) {
                return false;
            }
        }

        try {
            // Determine the best MIME type
            let mimeType = config.audio.mimeType;
            if (!MediaRecorder.isTypeSupported(mimeType)) {
                console.warn(`AudioRecordingService: ${mimeType} not supported, trying fallback`);
                mimeType = config.audio.fallbackMimeType;

                if (!MediaRecorder.isTypeSupported(mimeType)) {
                    console.error('AudioRecordingService: No supported MIME type found');
                    if (this.onError) {
                        this.onError('Your browser does not support audio recording');
                    }
                    return false;
                }
            }

            console.log(`AudioRecordingService: Using MIME type: ${mimeType}`);

            this.mediaRecorder = new MediaRecorder(this.audioStream, {
                mimeType: mimeType,
            });

            // Handle audio data chunks
            this.mediaRecorder.ondataavailable = (event) => {
                if (event.data && event.data.size > 0) {
                    this.processAudioChunk(event.data);
                }
            };

            this.mediaRecorder.onerror = (event) => {
                console.error('AudioRecordingService: MediaRecorder error', event);
                if (this.onError) {
                    this.onError('Recording error occurred');
                }
            };

            this.mediaRecorder.onstop = () => {
                console.log('AudioRecordingService: Recording stopped');
                this.isRecording = false;

                if (this.onRecordingStop) {
                    this.onRecordingStop();
                }
            };

            // Start recording with time slices for chunked data
            this.mediaRecorder.start(config.audio.chunkInterval);
            this.isRecording = true;

            console.log('AudioRecordingService: Recording started');

            if (this.onRecordingStart) {
                this.onRecordingStart();
            }

            return true;
        } catch (error) {
            console.error('AudioRecordingService: Failed to start recording', error);
            if (this.onError) {
                this.onError('Failed to start recording');
            }
            return false;
        }
    }

    /**
     * Stop recording audio
     */
    stopRecording() {
        if (!this.isRecording || !this.mediaRecorder) {
            console.warn('AudioRecordingService: Not currently recording');
            return;
        }

        try {
            this.mediaRecorder.stop();
            console.log('AudioRecordingService: Stopping recording');
        } catch (error) {
            console.error('AudioRecordingService: Error stopping recording', error);
        }
    }

    /**
     * Process audio chunk and convert to base64
     */
    async processAudioChunk(blob) {
        try {
            const arrayBuffer = await blob.arrayBuffer();
            const base64Data = arrayBufferToBase64(arrayBuffer);

            console.log(`AudioRecordingService: Processed chunk (${blob.size} bytes)`);

            if (this.onAudioChunk) {
                this.onAudioChunk(base64Data);
            }
        } catch (error) {
            console.error('AudioRecordingService: Failed to process audio chunk', error);
        }
    }

    /**
     * Release microphone and clean up resources
     */
    cleanup() {
        if (this.mediaRecorder && this.isRecording) {
            this.stopRecording();
        }

        if (this.audioStream) {
            this.audioStream.getTracks().forEach(track => track.stop());
            this.audioStream = null;
            console.log('AudioRecordingService: Audio stream released');
        }

        this.mediaRecorder = null;
        this.isRecording = false;
    }

    /**
     * Check if microphone permission is granted
     */
    async checkPermission() {
        try {
            const result = await navigator.permissions.query({ name: 'microphone' });
            return result.state === 'granted';
        } catch (error) {
            // Permissions API not supported, assume we need to request
            return false;
        }
    }
}

export default new AudioRecordingService();
