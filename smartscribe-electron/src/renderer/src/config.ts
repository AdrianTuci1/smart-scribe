// Configuration for the VoiceScribe frontend application

const config = {
    // WebSocket server configuration
    websocket: {
        url: 'wss://api.smartscribe.app/socket/websocket', // Electron app always points to prod or specific dev env, using prod URL for now or localhost if overridden
        // For development default to localhost if needed, but typically electron app might want real server
        // Let's keep logic similar to frontend but maybe simpler since we don't have import.meta.env.PROD the same way always
        // leveraging a simple check or defaulting to localhost for dev
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

// Override URL for development
if (process.env.NODE_ENV === 'development') {
    config.websocket.url = 'ws://localhost:4000/socket/websocket';
}

export const API_CONFIG = {
    BASE_URL: process.env.NODE_ENV === 'production'
        ? 'https://api.smartscribe.app'
        : 'http://localhost:4000/api'
};

export default config;
