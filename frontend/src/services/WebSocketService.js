/**
 * WebSocket Service - Main thread interface to WebSocket Worker
 * Communicates with the worker to handle WebSocket operations
 */
class WebSocketService {
    constructor() {
        this.worker = null;
        this.isConnected = false;
        this.sessionId = null;

        // Callbacks
        this.onTranscriptionComplete = null;
        this.onTranscriptContent = null;
        this.onError = null;
        this.onConnected = null;
        this.onDisconnected = null;

        this.initWorker();
    }

    /**
     * Initialize the Web Worker
     */
    initWorker() {
        try {
            this.worker = new Worker(
                new URL('../workers/websocket.worker.js', import.meta.url),
                { type: 'module' }
            );

            this.worker.onmessage = (event) => {
                this.handleWorkerMessage(event.data);
            };

            this.worker.onerror = (error) => {
                console.error('WebSocketService: Worker error', error);
                if (this.onError) {
                    this.onError('Worker error occurred');
                }
            };

            console.log('WebSocketService: Worker initialized');
        } catch (error) {
            console.error('WebSocketService: Failed to create worker', error);
            if (this.onError) {
                this.onError('Failed to initialize WebSocket worker');
            }
        }
    }

    /**
     * Handle messages from the worker
     */
    handleWorkerMessage(data) {
        const { type, payload } = data;

        switch (type) {
            case 'CONNECTED':
                this.isConnected = true;
                this.sessionId = payload.sessionId;
                console.log('WebSocketService: Connected with session', this.sessionId);
                if (this.onConnected) {
                    this.onConnected();
                }
                break;

            case 'DISCONNECTED':
                this.isConnected = false;
                this.sessionId = null;
                console.log('WebSocketService: Disconnected');
                if (this.onDisconnected) {
                    this.onDisconnected();
                }
                break;

            case 'TRANSCRIPTION_COMPLETE':
                if (this.onTranscriptionComplete) {
                    this.onTranscriptionComplete(payload.transcript);
                }
                break;

            case 'TRANSCRIPT_CONTENT':
                if (this.onTranscriptContent) {
                    this.onTranscriptContent(payload.content);
                }
                break;

            case 'ERROR':
                console.error('WebSocketService: Error from worker', payload.message);
                if (this.onError) {
                    this.onError(payload.message);
                }
                break;

            default:
                console.warn('WebSocketService: Unknown worker message type', type);
        }
    }

    /**
     * Connect to WebSocket server
     */
    connect() {
        if (this.isConnected) {
            console.log('WebSocketService: Already connected');
            return;
        }

        this.worker.postMessage({ type: 'CONNECT' });
    }

    /**
     * Disconnect from WebSocket server
     */
    disconnect() {
        this.worker.postMessage({ type: 'DISCONNECT' });
    }

    /**
     * Start the audio stream
     */
    startStream() {
        this.worker.postMessage({ type: 'START_STREAM' });
    }

    /**
     * Stop the audio stream
     */
    stopStream() {
        this.worker.postMessage({ type: 'STOP_STREAM' });
    }

    /**
     * Send audio chunk to server
     */
    sendAudioChunk(base64Data) {
        console.log('WebSocketService: Sending audio chunk to worker, length:', base64Data.length);
        this.worker.postMessage({
            type: 'SEND_AUDIO_CHUNK',
            payload: { data: base64Data }
        });
    }

    /**
     * Terminate the worker
     */
    terminate() {
        if (this.worker) {
            this.worker.terminate();
            this.worker = null;
            this.isConnected = false;
            this.sessionId = null;
            console.log('WebSocketService: Worker terminated');
        }
    }
}

export default new WebSocketService();
