// WebSocket Worker - Handles WebSocket communication in a separate thread

console.log('WebSocketWorker: Worker script loaded');

let ws: WebSocket | null = null;
let isConnected = false;
let sessionId: string | null = null;
let heartbeatTimer: NodeJS.Timeout | null = null;
let hasStartedStream = false; // Track if we've already started the stream
const websocketUrl = import.meta.env.VITE_WEBSOCKET_URL || 'ws://localhost:4000/socket/websocket'; // Default fallback
const heartbeatInterval = 30000; // 30 seconds

// Types for messages
interface WorkerMessage {
    type: string;
    payload?: any;
}

// Listen for messages from main thread
self.addEventListener('message', (event: MessageEvent) => {
    console.log('WebSocketWorker: Received message from main thread:', event.data.type);
    const { type, payload } = event.data as WorkerMessage;

    switch (type) {
        case 'CONNECT':
            // Allow passing URL in payload if needed, currently hardcoded fallback/default
            connect(payload?.url);
            break;
        case 'DISCONNECT':
            disconnect();
            break;
        case 'START_STREAM':
            startStream();
            break;
        case 'STOP_STREAM':
            stopStream();
            break;
        case 'SEND_AUDIO_CHUNK':
            sendAudioChunk(payload.data);
            break;
        default:
            console.warn('WebSocketWorker: Unknown message type:', type);
    }
});

function connect(url?: string) {
    if (isConnected || ws) {
        console.log('WebSocketWorker: Already connected or connecting');
        postMessage({ type: 'ERROR', payload: { message: 'Already connected' } });
        return;
    }

    // Only generate sessionId if we don't have one
    if (!sessionId) {
        sessionId = generateUUID();
        console.log(`WebSocketWorker: Generated new session ID: ${sessionId}`);
    } else {
        console.log(`WebSocketWorker: Reusing existing session ID: ${sessionId}`);
    }

    const targetUrl = url || websocketUrl;
    console.log(`WebSocketWorker: Connecting to ${targetUrl}`);

    try {
        ws = new WebSocket(targetUrl);
        console.log('WebSocketWorker: WebSocket instance created');

        ws.onopen = () => {
            console.log('WebSocketWorker: Connected');
            isConnected = true;
            joinChannel();
            startHeartbeat();
            postMessage({ type: 'CONNECTED', payload: { sessionId } });
        };

        ws.onmessage = (event) => {
            handleMessage(event.data);
        };

        ws.onerror = (error) => {
            console.error('WebSocketWorker: WebSocket error', error);
            // Type assertion since Event doesn't have detailed error props by default in standard typings
            // but checking standard WebSocket error event
            postMessage({ type: 'ERROR', payload: { message: 'WebSocket connection error' } });
        };

        ws.onclose = (event) => {
            console.log('WebSocketWorker: Disconnected');
            console.log('WebSocketWorker: Close details:', {
                code: event.code,
                reason: event.reason,
                wasClean: event.wasClean
            });
            isConnected = false;
            stopHeartbeat();
            ws = null;
            postMessage({ type: 'DISCONNECTED' });
        };
    } catch (error) {
        console.error('WebSocketWorker: Failed to create WebSocket', error);
        postMessage({ type: 'ERROR', payload: { message: 'Failed to create WebSocket connection' } });
    }
}

function disconnect() {
    stopHeartbeat();

    if (ws) {
        ws.onclose = null;
        ws.onerror = null;
        ws.close();
        ws = null;
    }

    isConnected = false;
    sessionId = null; // Clear sessionId for next session
    hasStartedStream = false; // Reset stream flag
    console.log('WebSocketWorker: Disconnected and cleared session');
    postMessage({ type: 'DISCONNECTED' });
}

function joinChannel() {
    const payload = {
        topic: `audio:${sessionId}`,
        event: 'phx_join',
        payload: {},
        ref: generateUUID()
    };

    sendMessage(payload);
    console.log(`WebSocketWorker: Joining channel audio:${sessionId}`);
}

function startStream() {
    // IMPORTANT: Use sessionId as user_id because server broadcasts to "audio:#{user_id}"
    // We need to match the topic we joined: "audio:#{sessionId}"
    const payload = {
        topic: `audio:${sessionId}`,
        event: 'start_stream',
        payload: { user_id: sessionId }, // Use sessionId here to match broadcast topic
        ref: generateUUID()
    };

    sendMessage(payload);
    console.log('WebSocketWorker: Starting stream with user_id:', sessionId);
}

function stopStream() {
    const payload = {
        topic: `audio:${sessionId}`,
        event: 'stop_stream',
        payload: {},
        ref: generateUUID()
    };

    sendMessage(payload);
    console.log('WebSocketWorker: Stopping stream');
}

function sendAudioChunk(base64Data: string) {
    if (!isConnected || !sessionId) {
        console.warn('WebSocketWorker: Cannot send audio chunk - not connected');
        return;
    }

    // console.log(`WebSocketWorker: Sending audio chunk, length: ${base64Data.length}`);

    const payload = {
        topic: `audio:${sessionId}`,
        event: 'audio_chunk',
        payload: { data: base64Data },
        ref: generateUUID()
    };

    sendMessage(payload);
}

function sendMessage(message: any) {
    if (!ws || ws.readyState !== WebSocket.OPEN) {
        console.warn('WebSocketWorker: Cannot send message - WebSocket not open');
        return;
    }

    try {
        ws.send(JSON.stringify(message));
    } catch (error) {
        console.error('WebSocketWorker: Failed to send message', error);
    }
}

function handleMessage(data: string) {
    try {
        const message = JSON.parse(data);
        const event = message.event;

        console.log('WebSocketWorker: Received event:', event);

        switch (event) {
            case 'phx_reply':
                handlePhxReply(message);
                break;

            case 'transcription_complete':
                if (message.payload && message.payload.transcript) {
                    console.log('WebSocketWorker: Transcription complete');
                    postMessage({
                        type: 'TRANSCRIPTION_COMPLETE',
                        payload: { transcript: message.payload.transcript }
                    });
                }
                break;

            case 'transcript_content':
                if (message.payload && message.payload.content) {
                    console.log('WebSocketWorker: Transcript content received');
                    postMessage({
                        type: 'TRANSCRIPT_CONTENT',
                        payload: { content: message.payload.content }
                    });
                }
                break;

            default:
                console.log('WebSocketWorker: Unhandled event:', event, message);
        }
    } catch (error) {
        console.error('WebSocketWorker: Failed to parse message', error);
    }
}

function handlePhxReply(message: any) {
    if (message.payload && message.payload.status === 'error') {
        console.error('WebSocketWorker: Phoenix error:', message.payload);
        const response = message.payload.response;
        // Parse the error reason whether it's an object or string
        let msg = 'Unknown error';
        if (typeof response === 'string') {
            msg = response;
        } else if (response && typeof response === 'object' && response.reason) {
            msg = response.reason;
        } else if (response && typeof response === 'object' && response.message) {
            msg = response.message;
        }

        postMessage({
            type: 'ERROR',
            payload: { message: msg }
        });
    } else if (message.payload && message.payload.status === 'ok') {
        console.log('WebSocketWorker: Phoenix reply OK for ref:', message.ref);

        // Only start stream once after successful join
        if (!hasStartedStream) {
            console.log('WebSocketWorker: Starting stream after successful join');
            hasStartedStream = true;
            startStream();
        } else {
            console.log('WebSocketWorker: Stream already started, skipping');
        }
    }
}

function startHeartbeat() {
    // Clear any existing heartbeat to avoid duplicates
    stopHeartbeat();

    heartbeatTimer = setInterval(() => {
        const payload = {
            topic: 'phoenix',
            event: 'heartbeat',
            payload: {},
            ref: generateUUID()
        };
        sendMessage(payload);
    }, heartbeatInterval);
}

function stopHeartbeat() {
    if (heartbeatTimer) {
        clearInterval(heartbeatTimer);
        heartbeatTimer = null;
    }
}

// Inline generateUUID since workers can't easily import from typical modules without bundler config for workers
// Copy-pasting the simple uuid implementation
function generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}
