import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import './TryNow.css';

const TryNow = () => {
    const navigate = useNavigate();
    const [isRecording, setIsRecording] = useState(false);
    const [isHovering, setIsHovering] = useState(false);
    const [transcripts, setTranscripts] = useState([]); // Keep empty for now
    const [timerSeconds, setTimerSeconds] = useState(0);
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

    // Keyboard interaction (Hold Space to Record)
    useEffect(() => {
        const handleKeyDown = (e) => {
            if (e.key === ' ' && !e.repeat) {
                e.preventDefault();
                setIsRecording(true);
            }
        };

        const handleKeyUp = (e) => {
            if (e.key === ' ') {
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

    const toggleRecording = () => {
        setIsRecording(prev => !prev);
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
                {transcripts.length === 0 && !isRecording && (
                    <div className="chat-placeholder">
                        <h2>Ready to transcribe?</h2>
                        <p>Press the orb or hold space to start.</p>
                    </div>
                )}

                <div className="transcription-container">
                    {isRecording && transcripts.length === 0 && (
                        <div className="transcription-box">
                            Your transcription will appear here once you finish speaking
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
