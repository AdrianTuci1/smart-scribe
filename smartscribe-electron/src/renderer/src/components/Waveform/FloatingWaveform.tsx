import React, { useState, useEffect, useRef } from 'react';
import './FloatingWaveform.css';
import { useAudioRecording } from '../../hooks/useAudioRecording';
import { WarningToast } from './WarningToast';
import { LimitToast } from './LimitToast';
import { RecordOrb } from './RecordOrb';
import { HoverHint } from './HoverHint';

export const FloatingWaveform: React.FC = () => {
    const {
        isRecording,
        setIsRecording,
        warningVisible,
        setWarningVisible,
        toggleRecording,
        limitReached,
        setLimitReached
    } = useAudioRecording();

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [isFullscreen, setIsFullscreen] = useState(false);
    const [pushToTalkKey, setPushToTalkKey] = useState<string>('Fn');
    const pushToTalkKeyRef = useRef('Fn');

    useEffect(() => {
        pushToTalkKeyRef.current = pushToTalkKey;
    }, [pushToTalkKey]);

    // Load Settings
    useEffect(() => {
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

    // Helper: Screen transparency & Fullscreen listener
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

    const isRecordingRef = useRef(isRecording);
    useEffect(() => {
        isRecordingRef.current = isRecording;
    }, [isRecording]);

    // Keyboard interaction via Global Monitor
    useEffect(() => {
        const handleGlobalKey = (keyData: any) => {
            const { type, modifiers, keyCode, chars } = keyData;
            const shortcut = pushToTalkKeyRef.current || 'Fn';

            // Debug log to verify we are receiving events
            // console.log('Global Key Event:', type, modifiers, keyCode, chars, 'Shortcut:', shortcut);

            const getRequiredParts = (s: string) => {
                return s.split('+').map(p => p.trim());
            };

            const requiredParts = getRequiredParts(shortcut);
            const currentModifiers = [...modifiers];
            let isMatch = false;

            const isModifierOnlyShortcut = requiredParts.every(p => ['Fn', 'Cmd', 'Command', 'Ctrl', 'Control', 'Alt', 'Shift', 'Option'].includes(p));

            if (isModifierOnlyShortcut) {
                const allRequiredPresent = requiredParts.every(req => currentModifiers.includes(req));
                const noExtras = currentModifiers.length === requiredParts.length;

                if (allRequiredPresent && noExtras) {
                    isMatch = true;
                }
            } else {
                const reqModifiers = requiredParts.filter(p => ['Fn', 'Cmd', 'Command', 'Ctrl', 'Control', 'Alt', 'Shift'].includes(p));
                const reqKey = requiredParts.find(p => !['Fn', 'Cmd', 'Command', 'Ctrl', 'Control', 'Alt', 'Shift'].includes(p));

                const modsMatch = reqModifiers.every(req => currentModifiers.includes(req)) && currentModifiers.length === reqModifiers.length;

                if (modsMatch && type === 'keydown' && reqKey) {
                    if (chars && chars.toUpperCase() === reqKey.toUpperCase()) {
                        isMatch = true;
                    }
                    else if (reqKey === 'Space' && keyCode === 49) {
                        isMatch = true;
                    }
                }
            }

            if (isMatch) {
                if (!isRecordingRef.current) {
                    console.log('Hotkey match! Starting recording...');
                    setIsRecording(true);
                }
            } else {
                if (isRecordingRef.current) {
                    console.log('Hotkey release/mismatch. Stopping recording...');
                    setIsRecording(false);
                }
            }
        };

        if ((window as any).electron && (window as any).electron.ipcRenderer) {
            console.log('Registering global-key-event listener');
            const removeListener = (window as any).electron.ipcRenderer.on('global-key-event', handleGlobalKey);
            return () => {
                console.log('Removing global-key-event listener');
                if (removeListener) removeListener();
            };
        }
        return () => { };
    }, []); // Empty dependency array to bind ONCE

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
                <HoverHint shortcutKey={pushToTalkKey} />

                <WarningToast
                    visible={warningVisible}
                    onClose={() => setWarningVisible(false)}
                />

                <LimitToast
                    visible={limitReached}
                    onClose={() => setLimitReached(false)}
                />

                <RecordOrb
                    isRecording={isRecording}
                    onClick={toggleRecording}
                    onContextMenu={handleRightClick}
                />
            </div>
        </div>
    );
};
