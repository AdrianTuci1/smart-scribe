import React, { useState, useEffect } from 'react';
import './FloatingWaveform.css';

export const FloatingWaveform: React.FC = () => {
    const [isRecording, setIsRecording] = useState(false);
    const [warningVisible, setWarningVisible] = useState(false);

    useEffect(() => {
        // Enable transparency for this window
        document.body.style.backgroundColor = 'transparent';
        document.documentElement.style.backgroundColor = 'transparent';

        return () => {
            // Revert (though typically this window closes, good practice)
            document.body.style.backgroundColor = '';
            document.documentElement.style.backgroundColor = '';
        };
    }, []);

    const toggleRecording = () => {
        if (!isRecording) {
            // Simulate check: if short click, show warning (demo logic)
            // For now, toggle normally but expose a way to test warning
            // Let's say right click triggers warning for demo purposes
            setIsRecording(true);
        } else {
            setIsRecording(false);
        }
        // Add IPC call here to start/stop actual recording
    };

    const handleRightClick = (e: React.MouseEvent) => {
        e.preventDefault();
        setWarningVisible(true);
        // Auto hide after 3 seconds
        setTimeout(() => setWarningVisible(false), 5000);
    };

    const handleMouseEnter = () => {
        (window as any).electron.ipcRenderer.send('set-ignore-mouse-events', false)
    }

    const handleMouseLeave = () => {
        (window as any).electron.ipcRenderer.send('set-ignore-mouse-events', true, { forward: true })
    }

    return (
        <div
            className="floating-waveform-wrapper"
            onMouseEnter={handleMouseEnter}
            onMouseLeave={handleMouseLeave}
        >
            <div className={`orb-container ${warningVisible ? 'has-warning' : ''}`}>
                {/* Hover Hint */}
                <div className="hover-hint">
                    Click or hold <span className="fn-key">fn</span> to start dictating
                </div>

                {/* Warning Toast */}
                {warningVisible && (
                    <div className="warning-toast">
                        <div className="warning-header">
                            <div className="warning-title">
                                <svg className="warning-icon" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z" />
                                </svg>
                                Don't tap. Hold down your shortcut.
                            </div>
                            <button className="warning-close-btn" onClick={() => setWarningVisible(false)}>
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" />
                                </svg>
                            </button>
                        </div>
                        <div className="warning-body">
                            Hold down your shortcut while speaking, and release to see your text.
                        </div>
                    </div>
                )}

                <button
                    className={`record-orb-btn ${isRecording ? 'recording' : ''}`}
                    onClick={toggleRecording}
                    onContextMenu={handleRightClick}
                >
                    <div className="btn-icon-wrapper">
                        {/* Mic Icon */}
                        <svg className="btn-icon icon-mic" viewBox="0 0 24 24">
                            <path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z" />
                            <path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z" />
                        </svg>

                        {/* Stop Icon */}
                        <svg className="btn-icon icon-stop" viewBox="0 0 24 24">
                            <rect x="6" y="6" width="12" height="12" rx="2" />
                        </svg>
                    </div>
                </button>
            </div>
        </div>
    );
};
