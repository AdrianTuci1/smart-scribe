import { useState, useEffect, useRef } from 'react';
import webSocketService from '../services/WebSocketService';
import audioRecordingService from '../services/AudioRecordingService';
import { authService } from '../services/auth';

interface UseAudioRecordingOptions {
    bypassTimer?: boolean;
    onTranscript?: (text: string) => void;
}

export const useAudioRecording = ({ bypassTimer = false, onTranscript }: UseAudioRecordingOptions = {}) => {
    const [isRecording, setIsRecording] = useState(false);
    const [recordingSource, setRecordingSource] = useState<'local' | 'external' | null>(null);
    const [warningVisible, setWarningVisible] = useState(false);
    const [limitReached, setLimitReached] = useState(false);
    const [isTranscribing, setIsTranscribing] = useState(false);

    // Refs
    const wasRecordingRef = useRef(false);
    const startTimerRef = useRef<any>(null);
    const realRecordingStartedRef = useRef(false);
    const isExternalRef = useRef(false); // Ref to track if current session is external to avoid closure staleness issues in effects if needed

    // Keep 'onTranscript' ref to access latest callback in closure
    const onTranscriptRef = useRef(onTranscript);
    useEffect(() => { onTranscriptRef.current = onTranscript; }, [onTranscript]);

    // Initialize services
    useEffect(() => {
        // WebSocket callbacks
        webSocketService.onTranscriptionComplete = async (transcript) => {
            console.log('Transcription complete event received (legacy/unused). Content:', transcript);
        };

        webSocketService.onConnected = () => {
            console.log('WebSocket connected.');
        };

        webSocketService.onError = (errorMsg) => {
            console.error('WebSocket error:', errorMsg);
            if ((window as any).electron) {
                (window as any).electron.ipcRenderer.send('log', 'WebSocket error:', errorMsg);
            }

            if (errorMsg === 'limit_exceeded') {
                setLimitReached(true);
                setTimeout(() => setLimitReached(false), 5000);
            }
            setIsTranscribing(false);

            // If real recording was active, we should behave like a stop
            if (realRecordingStartedRef.current && recordingSource === 'local') {
                setIsRecording(false);
                setRecordingSource(null);
            }
        };

        webSocketService.onTranscriptContent = async (content) => {
            // Debug log to confirm hook is receiving data
            if ((window as any).electron) {
                (window as any).electron.ipcRenderer.send('log', 'HOOK: Transcript content received', content);
            }

            setIsTranscribing(false);

            if (!content) {
                console.error('Empty content received');
                return;
            }

            // Custom handler if provided
            if (onTranscriptRef.current) {
                onTranscriptRef.current(content);
            }

            // 1. ALWAYS Try to write to clipboard first as a safe fallback
            try {
                if ((window as any).electron) {
                    (window as any).electron.ipcRenderer.send('clipboard-write', content);
                    // Notify main window to refresh
                    (window as any).electron.ipcRenderer.send('transcript-created', { content });
                }
            } catch (err) {
                console.error('Failed to write to clipboard:', err);
            }

            // 2. Try to intelligently paste if focused
            try {
                if ((window as any).electron) {
                    console.log('Checking input focus...');

                    // Add a timeout to the invoke via Promise.race
                    const focusCheckPromise = (window as any).electron.ipcRenderer.invoke('check-input-focus');
                    const isFocused = await Promise.race([
                        focusCheckPromise,
                        new Promise(resolve => setTimeout(() => resolve(false), 1000))
                    ]);

                    console.log('Input focus check result:', isFocused);

                    if (isFocused) {
                        console.log('Attempting to insert text...');
                        const success = await (window as any).electron.ipcRenderer.invoke('insert-text', content);
                        console.log('Insert text result:', success);
                    }
                }
            } catch (e) {
                console.error('Error in smart paste logic:', e);
            }
        };

        // Audio recording callbacks
        audioRecordingService.onAudioChunk = (base64Data) => {
            // Simplified: Just send. We only start recording after threshold now.
            if (webSocketService.isConnected) {
                webSocketService.sendAudioChunk(base64Data);
            }
        };

        audioRecordingService.onError = (errorMsg) => {
            console.error('Audio recording error:', errorMsg);
            setIsRecording(false);
            setRecordingSource(null);
            setIsTranscribing(false);
        };

        return () => {
            audioRecordingService.cleanup();
            if (startTimerRef.current) clearTimeout(startTimerRef.current);
        }
    }, [recordingSource]); // Re-bind if recordingSource changes? Actually listeners are static usually.

    // IPC Synchronization
    useEffect(() => {
        if (!(window as any).electron) return;

        const handleRemoteState = (_event: any, { isRecording: remoteIsRecording, source }: any) => {
            console.log('IPC: Received recording state update:', remoteIsRecording, source);
            if ((window as any).electron) {
                (window as any).electron.ipcRenderer.send('log', 'IPC: Received recording state update:', remoteIsRecording, source);
            }

            if (remoteIsRecording) {
                // Remote started recording
                isExternalRef.current = true;
                setRecordingSource('external');
                setIsRecording(true);
            } else {
                // Remote stopped recording
                isExternalRef.current = false;
                setRecordingSource(null);
                setIsRecording(false);
            }
        };

        const removeListener = (window as any).electron.ipcRenderer.on('recording-state-updated', handleRemoteState);

        return () => {
            removeListener();
        };
    }, []);

    // Broadcast local state changes
    useEffect(() => {
        // Only broadcast if WE are the source or became the source
        // Actually, whenever state changes, we might want to broadcast if it was a LOCAL change.
        // But we distinguish local vs external set via the `recordingSource` state logic or refs.
        // If `setIsRecording` was called by `toggleRecording` (user interaction), we set source to 'local'.
        // If called by IPC, source is 'external'.

        // We handle broadcast in the toggle function or effect?
        // Let's do it in the effect BUT protect against loops using source.

        if ((window as any).electron && recordingSource === 'local') {
            (window as any).electron.ipcRenderer.send('sync-recording-state', { isRecording, source: 'local' });
        }
    }, [isRecording, recordingSource]);


    // Manage recording state changes from UI/Shortcut
    useEffect(() => {
        if (isRecording) {
            handleStartRequest();
        } else if (wasRecordingRef.current) {
            handleStopRequest();
        }
        wasRecordingRef.current = isRecording;
    }, [isRecording]);

    const handleStartRequest = () => {
        // If external, DO NOT start local audio services
        if (recordingSource === 'external') {
            console.log('Recording started externally. UI updated only.');
            return;
        }

        console.log('Start request received.');
        if ((window as any).electron) {
            (window as any).electron.ipcRenderer.send('log', 'Start request received.');
        }

        realRecordingStartedRef.current = false;

        const startRealRecording = async () => {
            console.log('Starting REAL recording...');
            if ((window as any).electron) {
                (window as any).electron.ipcRenderer.send('log', 'Starting REAL recording...');
            }

            realRecordingStartedRef.current = true;
            startTimerRef.current = null;

            // 1. Connect WS
            const user = authService.getUser();
            webSocketService.connect(user?.id);

            // 2. Start Mic
            const success = await audioRecordingService.startRecording();
            if (!success) {
                console.error('Failed to start recording');
                if ((window as any).electron) {
                    (window as any).electron.ipcRenderer.send('log', 'Failed to start recording');
                }
                // Force stop
                webSocketService.disconnect();
                setIsRecording(false);
                setRecordingSource(null);
            } else {
                if ((window as any).electron) {
                    (window as any).electron.ipcRenderer.send('log', 'Real recording active.');
                }
            }
        };

        if (bypassTimer) {
            startRealRecording();
        } else {
            // Check settings for Mute Music
            if ((window as any).electron && (window as any).electron.ipcRenderer) {
                (window as any).electron.ipcRenderer.getAllSettings().then((settings: any) => {
                    if (settings && settings.muteMusicWhileDictating) {
                        console.log('Mute Music enabled. Sending mute-music IPC...');
                        (window as any).electron.ipcRenderer.send('mute-music');
                    }
                });
            }

            // Start a timer. If user releases before this fires, it's a short press.
            startTimerRef.current = setTimeout(startRealRecording, 600);
        }
    };

    const handleStopRequest = () => {
        console.log('Stop request received.');
        if ((window as any).electron) {
            (window as any).electron.ipcRenderer.send('log', 'Stop request received.');
        }

        // If external, just allow state to reset (Ref is already handled)
        if (recordingSource === 'external') {
            return;
        }

        // Check if we ever started real recording
        if (startTimerRef.current) {
            // Timer is still running -> We haven't reached 600ms yet!
            console.log('Short press detected (<600ms). Cancelling timer.');
            if ((window as any).electron) {
                (window as any).electron.ipcRenderer.send('log', 'Short press detected (<600ms). Cancelling timer.');
            }

            clearTimeout(startTimerRef.current);
            startTimerRef.current = null;
            realRecordingStartedRef.current = false;

            // Show warning
            setWarningVisible(true);
            setTimeout(() => {
                console.log('Hiding warning toast');
                setWarningVisible(false);
            }, 2000);

            // No cleanup needed for services because they never started!
            return;
        }

        if (realRecordingStartedRef.current) {
            console.log('Stopping REAL recording...');
            if ((window as any).electron) {
                (window as any).electron.ipcRenderer.send('log', 'Stopping REAL recording...');
            }

            audioRecordingService.stopRecording();
            webSocketService.stopStream();
            setIsTranscribing(true);

            // Wait for final transcription then disconnect
            setTimeout(() => {
                webSocketService.disconnect();
                if ((window as any).electron) {
                    (window as any).electron.ipcRenderer.send('log', 'WebSocket disconnected (timeout)');
                }
                setIsTranscribing(false);
            }, 5000); // Keep connection alive for a bit for final results

            realRecordingStartedRef.current = false;
        }
    };

    const toggleRecording = () => {
        setIsRecording(prev => {
            const newState = !prev;
            if (newState) {
                setRecordingSource('local');
            } else {
                setRecordingSource(null);
            }
            return newState;
        });
    };

    return {
        isRecording,
        setIsRecording,
        recordingSource,
        warningVisible,
        setWarningVisible,
        toggleRecording,
        limitReached,
        setLimitReached,
        isTranscribing
    };
};
