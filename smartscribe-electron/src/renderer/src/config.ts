// Configuration for the VoiceScribe frontend application

const config = {
    // WebSocket server configuration
    websocket: {
        url: import.meta.env.VITE_WEBSOCKET_URL || 'wss://api.smartscribe.app/socket/websocket',
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
// Consolidating logic: if VITE_WEBSOCKET_URL is provided, it's used above.
// If explicitly needed to override based on NODE_ENV separately from .env (rare if using .env), we can keep it,
// but usually .env dictates. 
// Removing the manual override block since we expect .env to handle it.

export const API_CONFIG = {
    BASE_URL: import.meta.env.VITE_API_BASE_URL || (process.env.NODE_ENV === 'production'
        ? 'https://api.smartscribe.app'
        : 'http://localhost:4000/api')
};

export default config;
