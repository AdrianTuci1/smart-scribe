import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import './TryNow.css';
import webSocketService from '../services/WebSocketService.js';
import audioRecordingService from '../services/AudioRecordingService.js';

const TryNow = () => {
    const navigate = useNavigate();
    const [isRecording, setIsRecording] = useState(false);
    const [isHovering, setIsHovering] = useState(false);
    const [transcripts, setTranscripts] = useState([]); // Keep empty for now
    const [timerSeconds, setTimerSeconds] = useState(0);
    const [userInput, setUserInput] = useState('');
    const [error, setError] = useState(null);
    const [isConnecting, setIsConnecting] = useState(false);
    const bottomRef = useRef(null);
    const pressStartTime = useRef(0);
    const pressTimeout = useRef(null);
    const wasRecordingRef = useRef(false);

    useEffect(() => {
        let interval;
        if (isRecording) {
            interval = setInterval(() => {
                setTimerSeconds(prev => prev + 1);
            }, 1000);
        } else {
            setTimerSeconds(0);
        }
        return () => clearInterval(interval);
    }, [isRecording]);

    useEffect(() => {
        if (bottomRef.current) {
            bottomRef.current.scrollIntoView({ behavior: 'smooth' });
        }
    }, [transcripts]);

    // Keyboard interaction (Hold Control to Record)
    useEffect(() => {
        const handleKeyDown = (e) => {
            if (e.key === 'Control' && !e.repeat) {
                e.preventDefault();
                setIsRecording(true);
            }
        };

        const handleKeyUp = (e) => {
            if (e.key === 'Control') {
                e.preventDefault();
                setIsRecording(false);
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        window.addEventListener('keyup', handleKeyUp);
        return () => {
            window.removeEventListener('keydown', handleKeyDown);
            window.removeEventListener('keyup', handleKeyUp);
        };
    }, []);

    // Initialize services and set up callbacks
    useEffect(() => {
        // Request microphone permission on mount
        audioRecordingService.requestMicrophonePermission().then(granted => {
            if (granted) {
                console.log('TryNow: Microphone permission granted on mount');
            } else {
                setError('Microphone permission is required for transcription');
            }
        });

        // WebSocket callbacks
        webSocketService.onTranscriptContent = (content) => {
            console.log('TryNow: Received transcript content:', content);
            setUserInput(content);
        };

        webSocketService.onTranscriptionComplete = (transcript) => {
            console.log('TryNow: Transcription complete:', transcript);
            setUserInput(transcript);
        };

        webSocketService.onError = (errorMsg) => {
            console.error('TryNow: WebSocket error:', errorMsg);
            setError(errorMsg);
            setIsRecording(false);
        };

        webSocketService.onConnected = () => {
            console.log('TryNow: WebSocket connected');
            setIsConnecting(false);
        };

        webSocketService.onDisconnected = () => {
            console.log('TryNow: WebSocket disconnected');
            setIsConnecting(false);
        };

        // Audio recording callbacks
        audioRecordingService.onAudioChunk = (base64Data) => {
            webSocketService.sendAudioChunk(base64Data);
        };

        audioRecordingService.onError = (errorMsg) => {
            console.error('TryNow: Audio recording error:', errorMsg);
            setError(errorMsg);
            setIsRecording(false);
        };

        audioRecordingService.onRecordingStart = () => {
            console.log('TryNow: Recording started');
        };

        audioRecordingService.onRecordingStop = () => {
            console.log('TryNow: Recording stopped');
        };

        // Cleanup on unmount
        return () => {
            webSocketService.disconnect();
            audioRecordingService.cleanup();
        };
    }, []);

    const startRecording = async () => {
        if (audioRecordingService.isRecording || webSocketService.isConnected) {
            console.warn('TryNow: Already recording or connected');
            return;
        }

        setError(null);
        setIsConnecting(true);

        // Connect WebSocket
        webSocketService.connect();

        // Start audio recording
        const success = await audioRecordingService.startRecording();
        if (!success) {
            setIsRecording(false);
            setIsConnecting(false);
            webSocketService.disconnect();
        }
    };

    const stopRecording = () => {
        if (!audioRecordingService.isRecording) {
            console.warn('TryNow: Not currently recording');
            return;
        }

        audioRecordingService.stopRecording();
        webSocketService.stopStream();
        // Keep WebSocket connected briefly to receive final transcription
        setTimeout(() => {
            webSocketService.disconnect();
        }, 2000);
    };

    const toggleRecording = () => {
        if (isRecording) {
            stopRecording();
            setIsRecording(false);
        } else {
            setIsRecording(true);
            startRecording();
        }
    };

    const goBack = () => {
        navigate('/');
    };

    const formatTime = (seconds) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    };

    return (
        <div className="try-now-page">
            <header className="try-now-header">
                <button onClick={goBack} className="back-button">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M19 12H5M12 19l-7-7 7-7" />
                    </svg>
                    Back to Home
                </button>
            </header>

            <div className="try-now-chat-area">
                <div className="transcription-container">
                    <textarea
                        className="transcription-placeholder"
                        placeholder="I prefer to plan a week-long itinerary to the Carpathians. Include hiking trails, traditional villages, and local cuisine recommendations. Make sure to highlight the best time to visit and any cultural festivals happening during the year."
                        value={userInput}
                        onChange={(e) => setUserInput(e.target.value)}
                        rows={5}
                    />
                    {!isRecording && transcripts.length === 0 && (
                        <div className="transcription-helper-text">
                            Press the orb or hold Control to start the transcription
                        </div>
                    )}
                    {error && (
                        <div className="transcription-error-text">
                            {error}
                        </div>
                    )}
                    {/* Empty for now as requested */}
                    <div ref={bottomRef} />
                </div>
            </div>

            <div className="try-now-dock-wrapper">
                <div className="dock-side-panel">
                    {/* Placeholder for settings if needed */}
                </div>

                <div className="record-button-container">
                    <button
                        className={`record-orb-btn ${isRecording ? 'recording' : 'not-recording'}`}
                        onClick={toggleRecording}
                        onMouseEnter={() => setIsHovering(true)}
                        onMouseLeave={() => setIsHovering(false)}
                    >
                        {/* Orb Icons Wrapper (Center) */}
                        <div className="btn-icon-wrapper">
                            {/* Mic Icon (Hover when not recording) */}
                            <svg className="btn-icon icon-mic" viewBox="0 0 24 24" fill="currentColor">
                                <path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z" />
                                <path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z" />
                            </svg>

                            {/* Stop Icon (Hover when Recording) */}
                            <svg className="btn-icon icon-stop" viewBox="0 0 24 24" fill="currentColor">
                                <rect x="6" y="6" width="12" height="12" rx="2" />
                            </svg>
                        </div>
                    </button>
                </div>

                <div className="dock-side-panel">
                    {/* Placeholder */}
                </div>
            </div>
        </div>
    );
};

export default TryNow;
