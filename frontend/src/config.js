// Configuration for the VoiceScribe frontend application

const config = {
    // WebSocket server configuration
    websocket: {
        url: 'ws://localhost:4000/socket/websocket',
        reconnectInterval: 5000, // ms
        heartbeatInterval: 30000, // ms (30 seconds, matching Swift implementation)
    },

    // Audio recording configuration
    audio: {
        mimeType: 'audio/webm;codecs=opus', // Preferred format
        fallbackMimeType: 'audio/webm', // Fallback if opus not supported
        chunkInterval: 250, // ms - how often to send chunks (matching typical real-time streaming)
        sampleRate: 16000, // Hz - AWS Transcribe prefers 16kHz for speech
    },
};

export default config;
