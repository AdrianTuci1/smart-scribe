import { useState, useEffect, useRef } from 'react';
import webSocketService from '../services/WebSocketService';
import audioRecordingService from '../services/AudioRecordingService';

export const useAudioRecording = () => {
    const [isRecording, setIsRecording] = useState(false);
    const [warningVisible, setWarningVisible] = useState(false);
    const wasRecordingRef = useRef(false);

    // Timer ref to delay actual recording start
    // Using any to avoid NodeJS vs Window timeout type conflicts
    const startTimerRef = useRef<any>(null);
    // Flag to track if the REAL recording services have started
    const realRecordingStartedRef = useRef(false);

    // Initialize services
    useEffect(() => {
        // WebSocket callbacks
        webSocketService.onTranscriptionComplete = async (transcript) => {
            console.log('Transcription complete:', transcript);
            (window as any).electron.ipcRenderer.send('log', 'Transcription complete received', transcript);

            if (!transcript) {
                console.error('Empty transcript received');
                (window as any).electron.ipcRenderer.send('log', 'Empty transcript received');
                return;
            }

            // Check if user has a text input focused
            try {
                console.log('Checking input focus...');
                (window as any).electron.ipcRenderer.send('log', 'Checking input focus via IPC...');
                const isFocused = await (window as any).electron.ipcRenderer.invoke('check-input-focus');
                console.log('Input focus check result:', isFocused);
                (window as any).electron.ipcRenderer.send('log', 'Input focus result:', isFocused);

                if (isFocused) {
                    // Simulate paste
                    console.log('Attempting to insert text...');
                    (window as any).electron.ipcRenderer.send('log', 'Attempting insert text');
                    const success = await (window as any).electron.ipcRenderer.invoke('insert-text', transcript);
                    console.log('Insert text result:', success);
                    (window as any).electron.ipcRenderer.send('log', 'Insert text success:', success);

                    if (!success) {
                        // Fallback
                        console.log('Insert failed, falling back to clipboard...');
                        (window as any).electron.ipcRenderer.send('log', 'Insert failed, fallback to clipboard');
                        (window as any).electron.ipcRenderer.send('clipboard-write', transcript);
                    }
                } else {
                    // Just copy to clipboard
                    console.log('Input not focused, copying to clipboard...');
                    (window as any).electron.ipcRenderer.send('log', 'Not focused, copying to clipboard');
                    (window as any).electron.ipcRenderer.send('clipboard-write', transcript);
                }
            } catch (e) {
                console.error('Error checking input focus:', e);
                // Fallback
                console.log('Exception caught, falling back to clipboard...');
                (window as any).electron.ipcRenderer.send('log', 'Exception in focus check:', e);
                (window as any).electron.ipcRenderer.send('clipboard-write', transcript);
            }
        };

        webSocketService.onConnected = () => {
            console.log('WebSocket connected.');
        };

        webSocketService.onError = (errorMsg) => {
            console.error('WebSocket error:', errorMsg);
            (window as any).electron.ipcRenderer.send('log', 'WebSocket error:', errorMsg);
            // If real recording was active, we should behave like a stop
            if (realRecordingStartedRef.current) {
                // UI update will trigger stopRecording logic if needed, 
                // but direct error -> force reset
                setIsRecording(false);
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
        };

        return () => {
            audioRecordingService.cleanup();
            if (startTimerRef.current) clearTimeout(startTimerRef.current);
        }
    }, []);

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
        console.log('Start request received. Waiting 600ms...');
        (window as any).electron.ipcRenderer.send('log', 'Start request received. Waiting 600ms...');

        realRecordingStartedRef.current = false;

        // Start a timer. If user releases before this fires, it's a short press.
        startTimerRef.current = setTimeout(async () => {
            console.log('600ms passed. Starting REAL recording...');
            (window as any).electron.ipcRenderer.send('log', '600ms passed. Starting REAL recording...');

            realRecordingStartedRef.current = true;
            startTimerRef.current = null;

            // 1. Connect WS
            webSocketService.connect();

            // 2. Start Mic
            const success = await audioRecordingService.startRecording();
            if (!success) {
                console.error('Failed to start recording');
                (window as any).electron.ipcRenderer.send('log', 'Failed to start recording');
                // Force stop
                webSocketService.disconnect();
                setIsRecording(false);
            } else {
                (window as any).electron.ipcRenderer.send('log', 'Real recording active.');
            }

        }, 600);
    };

    const handleStopRequest = () => {
        console.log('Stop request received.');
        (window as any).electron.ipcRenderer.send('log', 'Stop request received.');

        // Check if we ever started real recording
        if (startTimerRef.current) {
            // Timer is still running -> We haven't reached 600ms yet!
            console.log('Short press detected (<600ms). Cancelling timer.');
            (window as any).electron.ipcRenderer.send('log', 'Short press detected (<600ms). Cancelling timer.');

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
            (window as any).electron.ipcRenderer.send('log', 'Stopping REAL recording...');

            audioRecordingService.stopRecording();
            webSocketService.stopStream();

            // Wait for final transcription then disconnect
            setTimeout(() => {
                webSocketService.disconnect();
                (window as any).electron.ipcRenderer.send('log', 'WebSocket disconnected (timeout)');
            }, 5000); // Keep connection alive for a bit for final results

            realRecordingStartedRef.current = false;
        }
    };

    const toggleRecording = () => {
        setIsRecording(prev => !prev);
    };

    return {
        isRecording,
        setIsRecording,
        warningVisible,
        setWarningVisible,
        toggleRecording
    };
};
