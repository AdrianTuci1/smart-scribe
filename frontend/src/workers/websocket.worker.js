// WebSocket Worker - Handles WebSocket communication in a separate thread

let ws = null;
let isConnected = false;
let sessionId = null;
let heartbeatTimer = null;
const websocketUrl = 'ws://localhost:4000/socket/websocket';
const heartbeatInterval = 30000; // 30 seconds

// Listen for messages from main thread
self.addEventListener('message', (event) => {
    const { type, payload } = event.data;

    switch (type) {
        case 'CONNECT':
            connect();
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

function connect() {
    if (isConnected || ws) {
        console.log('WebSocketWorker: Already connected or connecting');
        postMessage({ type: 'ERROR', payload: { message: 'Already connected' } });
        return;
    }

    sessionId = generateUUID();
    console.log(`WebSocketWorker: Connecting to ${websocketUrl}`);
    console.log(`WebSocketWorker: Session ID: ${sessionId}`);

    try {
        ws = new WebSocket(websocketUrl);

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
            console.error('WebSocketWorker: Error', error);
            postMessage({ type: 'ERROR', payload: { message: 'WebSocket connection error' } });
        };

        ws.onclose = () => {
            console.log('WebSocketWorker: Disconnected');
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
    sessionId = null;
    console.log('WebSocketWorker: Disconnected');
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
    const payload = {
        topic: `audio:${sessionId}`,
        event: 'start_stream',
        payload: { user_id: sessionId },
        ref: generateUUID()
    };

    sendMessage(payload);
    console.log('WebSocketWorker: Starting stream');
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

function sendAudioChunk(base64Data) {
    if (!isConnected || !sessionId) {
        console.warn('WebSocketWorker: Cannot send audio chunk - not connected');
        return;
    }

    console.log(`WebSocketWorker: Sending audio chunk, length: ${base64Data.length}`);

    const payload = {
        topic: `audio:${sessionId}`,
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
        console.log('WebSocketWorker: Phoenix reply OK');
        if (message.ref) {
            startStream();
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
