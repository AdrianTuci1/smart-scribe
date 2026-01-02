// WebSocket Worker - Handles WebSocket communication in a separate thread

console.log('WebSocketWorker: Worker script loaded');

let ws = null;
let isConnected = false;
let sessionId = null;
let heartbeatTimer = null;
let hasStartedStream = false; // Track if we've already started the stream
const websocketUrl = 'ws://localhost:4000/socket/websocket';
const heartbeatInterval = 30000; // 30 seconds

// Listen for messages from main thread
self.addEventListener('message', (event) => {
    console.log('WebSocketWorker: Received message from main thread:', event.data.type);
    const { type, payload } = event.data;

    switch (type) {
        case 'CONNECT':
            connect(payload);
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

let isPublic = true; // Default to public mode as this worker is used on the unauthenticated website

// ... inside handlers
function connect(payload) {
    if (isConnected || ws) {
        console.log('WebSocketWorker: Already connected or connecting');
        postMessage({ type: 'ERROR', payload: { message: 'Already connected' } });
        return;
    }

    // Allow overriding if ever needed, but default is TRUE
    if (payload && typeof payload.isPublic !== 'undefined') {
        isPublic = payload.isPublic;
    }

    console.log(`WebSocketWorker: Connecting mode: ${isPublic ? 'PUBLIC' : 'PRIVATE'}`);

    // Only generate sessionId if we don't have one
    if (!sessionId) {
        sessionId = isPublic ? `public-${generateUUID()}` : generateUUID();
        console.log(`WebSocketWorker: Generated new session ID: ${sessionId}`);
    }

    console.log(`WebSocketWorker: Connecting to ${websocketUrl}`);
    // ... rest of connect logic matches existing
    try {
        ws = new WebSocket(websocketUrl);
        console.log('WebSocketWorker: WebSocket instance created');

        ws.onopen = () => {
            console.log('WebSocketWorker: Connected');
            isConnected = true;
            joinChannel();
            startHeartbeat();
            postMessage({ type: 'CONNECTED', payload: { sessionId } });
        };
        // ... handlers
        ws.onmessage = (event) => { handleMessage(event.data); };
        ws.onerror = (error) => {
            console.error('WebSocketWorker: WebSocket error', error);
            // ... existing error logging
            postMessage({ type: 'ERROR', payload: { message: 'WebSocket connection error' } });
        };
        ws.onclose = (event) => {
            // ... existing close logic
            isConnected = false;
            stopHeartbeat();
            ws = null;
            postMessage({ type: 'DISCONNECTED' });
        };
    } catch (error) {
        // ... existing error catch
        console.error('WebSocketWorker: Failed to create WebSocket', error);
        postMessage({ type: 'ERROR', payload: { message: 'Failed to create WebSocket connection' } });
    }
}

function joinChannel() {
    // Determine topic based on public/private mode
    const topic = isPublic ? `public_audio:${sessionId}` : `audio:${sessionId}`;

    const payload = {
        topic: topic,
        event: 'phx_join',
        payload: {},
        ref: generateUUID()
    };

    sendMessage(payload);
    console.log(`WebSocketWorker: Joining channel ${topic}`);
}

function startStream() {
    const topic = isPublic ? `public_audio:${sessionId}` : `audio:${sessionId}`;

    const payload = {
        topic: topic,
        event: 'start_stream',
        // For public stream, user_id is implicit/session_id, private uses sessionId as user_id proxy 
        // Logic remains same: send sessionId as ID if needed, or backend handles it.
        payload: { user_id: sessionId },
        ref: generateUUID()
    };

    sendMessage(payload);
    console.log('WebSocketWorker: Starting stream with user_id:', sessionId);
}

function stopStream() {
    const topic = isPublic ? `public_audio:${sessionId}` : `audio:${sessionId}`;

    const payload = {
        topic: topic,
        event: 'stop_stream',
        payload: {},
        ref: generateUUID()
    };

    sendMessage(payload);
    console.log('WebSocketWorker: Stopping stream');
}

function sendAudioChunk(base64Data) {
    if (!isConnected || !sessionId) {
        console.warn('WebSocketWorker: Cannot send audio chunk - not connected');
        return;
    }

    const topic = isPublic ? `public_audio:${sessionId}` : `audio:${sessionId}`;

    // console.log(`WebSocketWorker: Sending audio chunk, length: ${base64Data.length}`);

    const payload = {
        topic: topic,
        event: 'audio_chunk',
        payload: { data: base64Data },
        ref: generateUUID()
    };

    sendMessage(payload);
}

function sendMessage(message) {
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

function handleMessage(data) {
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

function handlePhxReply(message) {
    if (message.payload && message.payload.status === 'error') {
        console.error('WebSocketWorker: Phoenix error:', message.payload);
        postMessage({
            type: 'ERROR',
            payload: { message: message.payload.response || 'Unknown error' }
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

// Inline generateUUID since workers can't import from utils
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}
