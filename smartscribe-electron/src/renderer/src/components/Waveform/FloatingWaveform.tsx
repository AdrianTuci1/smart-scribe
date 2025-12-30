import React, { useState, useEffect, useRef } from 'react';
import './FloatingWaveform.css';
import webSocketService from '../../services/WebSocketService';
import audioRecordingService from '../../services/AudioRecordingService';

export const FloatingWaveform: React.FC = () => {
    const [isRecording, setIsRecording] = useState(false);
    const [warningVisible, setWarningVisible] = useState(false);
    const [isFullscreen, setIsFullscreen] = useState(false);
    const wasRecordingRef = useRef(false);

    const [pushToTalkKey, setPushToTalkKey] = useState<string>('Control');
    const pushToTalkKeyRef = useRef('Control');

    useEffect(() => {
        pushToTalkKeyRef.current = pushToTalkKey;
    }, [pushToTalkKey]);

    useEffect(() => {
        // Load settings to get the correct key
        const loadSettings = async () => {
            try {
                if ((window as any).electron && (window as any).electron.ipcRenderer) {
                    const settings = await (window as any).electron.ipcRenderer.getAllSettings();
                    if (settings && settings.pushToTalkKey) {
                        setPushToTalkKey(settings.pushToTalkKey);
                    }
                }
            } catch (err) {
                console.error("Failed to load settings in Waveform:", err);
            }
        };
        loadSettings();
    }, []);

    // Helper to check if event matches shortcut
    const isShortcutPressed = (e: KeyboardEvent, shortcut: string) => {
        const parts = shortcut.split('+');
        const modifiers: Record<string, boolean> = {
            Cmd: e.metaKey,
            Ctrl: e.ctrlKey,
            Alt: e.altKey,
            Shift: e.shiftKey
        };

        // Check modifiers
        const reqModifiers = parts.filter(p => ['Cmd', 'Ctrl', 'Alt', 'Shift'].includes(p));
        for (const mod of reqModifiers) {
            if (!modifiers[mod]) return false;
        }

        // Check main key
        const mainKeys = parts.filter(p => !['Cmd', 'Ctrl', 'Alt', 'Shift'].includes(p));
        if (mainKeys.length > 0) {
            const mainKey = mainKeys[0];
            const checkKey = e.code === 'Space' ? 'Space' : e.key.toUpperCase();
            if (checkKey !== mainKey.toUpperCase()) return false;
        } else {
            // Modifier only shortcut (e.g. "Control") - handle legacy/fallback
            if (reqModifiers.length === 1 && reqModifiers[0] === 'Ctrl' && e.key === 'Control') return true;
            // Add others if needed, but GeneralSettings prevents creating them usually.
        }

        return true;
    };

    const isShortcutReleased = (e: KeyboardEvent, shortcut: string) => {
        const parts = shortcut.split('+');
        let keyName = e.key;
        if (keyName === 'Meta') keyName = 'Cmd';
        if (keyName === 'Control') keyName = 'Ctrl';
        if (keyName === 'Alt') keyName = 'Alt';
        if (keyName === 'Shift') keyName = 'Shift';
        if (e.code === 'Space') keyName = 'Space';

        return parts.some(p => p.toUpperCase() === keyName.toUpperCase());
    };

    useEffect(() => {
        // Enable transparency for this window
        document.body.style.backgroundColor = 'transparent';
        document.documentElement.style.backgroundColor = 'transparent';

        // Listen for fullscreen state changes from main process
        const handleFullscreenChange = (_event: any, fullscreen: boolean) => {
            setIsFullscreen(fullscreen);
        };

        const unsubscribe = (window as any).electron.ipcRenderer.on('fullscreen-state-changed', handleFullscreenChange);

        return () => {
            document.body.style.backgroundColor = '';
            document.documentElement.style.backgroundColor = '';
            unsubscribe();
        };
    }, []);

    // Initialize services
    useEffect(() => {
        // WebSocket callbacks
        webSocketService.onTranscriptionComplete = async (transcript) => {
            console.log('Transcription complete:', transcript);

            // Check if user has a text input focused
            try {
                const isFocused = await (window as any).electron.ipcRenderer.invoke('check-input-focus');
                console.log('Input focus check:', isFocused);

                if (isFocused) {
                    // Simulate paste (Command+V)
                    const success = await (window as any).electron.ipcRenderer.invoke('insert-text', transcript);
                    if (!success) {
                        // Fallback
                        (window as any).electron.ipcRenderer.send('clipboard-write', transcript);
                    }
                } else {
                    // Just copy to clipboard
                    (window as any).electron.ipcRenderer.send('clipboard-write', transcript);
                }
            } catch (e) {
                console.error('Error checking input focus:', e);
                // Fallback
                (window as any).electron.ipcRenderer.send('clipboard-write', transcript);
            }
        };

        webSocketService.onError = (errorMsg) => {
            console.error('WebSocket error:', errorMsg);
            setIsRecording(false);
        };

        // Audio recording callbacks
        audioRecordingService.onAudioChunk = (base64Data) => {
            webSocketService.sendAudioChunk(base64Data);
        };

        audioRecordingService.onError = (errorMsg) => {
            console.error('Audio recording error:', errorMsg);
            setIsRecording(false);
        };

        return () => {
            audioRecordingService.cleanup();
        }
    }, []);

    // Manage recording state changes
    useEffect(() => {
        if (isRecording) {
            startRecording();
        } else if (wasRecordingRef.current) {
            stopRecording();
        }
        wasRecordingRef.current = isRecording;
    }, [isRecording]);

    // Keyboard interaction via Global Monitor
    useEffect(() => {
        const handleGlobalKey = (_event: any, keyData: any) => {
            const { type, modifiers, keyCode, chars } = keyData;
            const shortcut = pushToTalkKeyRef.current;

            // Basic matching logic
            // 1. Check modifiers
            const requiredModifiers = shortcut.split('+').filter(p => ['Cmd', 'Ctrl', 'Alt', 'Shift', 'Fn'].includes(p));
            // Note: Swift sends "Cmd", "Ctrl", "Alt", "Shift", "Fn" as strings in modifiers array

            const hasAllModifiers = requiredModifiers.every(req => modifiers.includes(req));
            const hasOnlyRequiredModifiers = modifiers.length === requiredModifiers.length;

            // 2. Check main key (if any)
            const mainKey = shortcut.split('+').find(p => !['Cmd', 'Ctrl', 'Alt', 'Shift', 'Fn'].includes(p));

            let isMatch = false;

            if (mainKey) {
                // We need to match key code or char
                // Since we rely on chars from Swift for non-modifier keys
                if (hasAllModifiers && hasOnlyRequiredModifiers && chars && chars.toUpperCase() === mainKey.toUpperCase()) {
                    isMatch = true;
                }
                // Fallback for special keys if needed (Space=Space)
                if (mainKey === 'Space' && keyCode === 49 && hasAllModifiers && hasOnlyRequiredModifiers) isMatch = true;
            } else {
                // Modifiers only match
                if (hasAllModifiers && hasOnlyRequiredModifiers) isMatch = true;
            }

            if (isMatch) {
                if (type === 'keydown' || (type === 'flagsChanged' && modifiers.length > 0)) { // Ensure flagsChanged is a press, not release
                    if (!isRecording) {
                        setIsRecording(true);
                    }
                } else if (type === 'keyup' || (type === 'flagsChanged' && modifiers.length < requiredModifiers.length)) {
                    if (isRecording) {
                        setIsRecording(false);
                    }
                }
            } else {
                // If modifiers mismatch during flagsChanged, it might be a release of one modifier
                // If we were recording and the combo is broken, stop recording
                if (isRecording && type === 'flagsChanged') {
                    // Check if the required modifiers are NO LONGER present
                    const stillHasAll = requiredModifiers.every(req => modifiers.includes(req));
                    if (!stillHasAll) {
                        setIsRecording(false);
                    }
                }
            }
        };

        if ((window as any).electron && (window as any).electron.ipcRenderer) {
            const removeListener = (window as any).electron.ipcRenderer.on('global-key-event', handleGlobalKey);
            return () => {
                if (removeListener) removeListener();
            };
        }
        return () => { };
    }, [isRecording]);

    const startRecording = async () => {
        if (audioRecordingService.isRecording) return;

        console.log('Starting recording...');
        webSocketService.connect();
        const success = await audioRecordingService.startRecording();

        if (!success) {
            console.error('Failed to start recording');
            setIsRecording(false);
            webSocketService.disconnect();
        }
    };

    const stopRecording = () => {
        if (!audioRecordingService.isRecording) return;

        console.log('Stopping recording...');
        audioRecordingService.stopRecording();
        webSocketService.stopStream();

        // Wait for final transcription then disconnect
        setTimeout(() => {
            webSocketService.disconnect();
        }, 5000);
    };

    const toggleRecording = () => {
        if (isRecording) {
            // User manually clicked stop
            setIsRecording(false);
        } else {
            // User manually clicked start
            setIsRecording(true);
        }
    };

    const handleRightClick = (e: React.MouseEvent) => {
        e.preventDefault();
        setWarningVisible(true);
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
                    Click or hold <span className="fn-key">{pushToTalkKey}</span> to start dictating
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
                                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 17.59 13.41 12z" />
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
