/**
 * WebSocket Service - Main thread interface to WebSocket Worker
 * Communicates with the worker to handle WebSocket operations
 */
class WebSocketService {
    private worker: Worker | null = null;
    public isConnected: boolean = false;
    public sessionId: string | null = null;

    // Callbacks
    public onTranscriptionComplete: ((transcript: string) => void) | null = null;
    public onTranscriptContent: ((content: string) => void) | null = null;
    public onError: ((errorMsg: string) => void) | null = null;
    public onConnected: (() => void) | null = null;
    public onDisconnected: (() => void) | null = null;

    constructor() {
        this.initWorker();
    }

    /**
     * Initialize the Web Worker
     */
    private initWorker() {
        try {
            // In Vite, we can import the worker constructor directly if configured, or use the standard new URL approach
            // adjusting path to match structure: ../workers/websocket.worker.ts
            // Note: Vite usually requires ?worker suffix for imports, but new URL also works.
            // However, referencing .ts worker file directly in new URL might require Vite's specific handling.
            // Let's try standard Vite way:
            this.worker = new Worker(
                new URL('../workers/websocket.worker.ts', import.meta.url),
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
    private handleWorkerMessage(data: any) {
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
                console.log('WebSocketService: Received TRANSCRIPT_CONTENT from worker. Handler exists?', !!this.onTranscriptContent);
                if (this.onTranscriptContent) {
                    this.onTranscriptContent(payload.content);
                } else {
                    console.warn('WebSocketService: No onTranscriptContent handler assigned!');
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
    public connect() {
        if (this.isConnected) {
            console.log('WebSocketService: Already connected');
            return;
        }

        if (this.worker) {
            this.worker.postMessage({ type: 'CONNECT' });
        }
    }

    /**
     * Disconnect from WebSocket server
     */
    public disconnect() {
        if (this.worker) {
            this.worker.postMessage({ type: 'DISCONNECT' });
        }
    }

    /**
     * Start the audio stream
     */
    public startStream() {
        if (this.worker) {
            this.worker.postMessage({ type: 'START_STREAM' });
        }
    }

    /**
     * Stop the audio stream
     */
    public stopStream() {
        if (this.worker) {
            this.worker.postMessage({ type: 'STOP_STREAM' });
        }
    }

    /**
     * Send audio chunk to server
     */
    public sendAudioChunk(base64Data: string) {
        // console.log('WebSocketService: Sending audio chunk to worker, length:', base64Data.length);
        if (this.worker) {
            this.worker.postMessage({
                type: 'SEND_AUDIO_CHUNK',
                payload: { data: base64Data }
            });
        }
    }

    /**
     * Terminate the worker
     */
    public terminate() {
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
