import React, { useState, useEffect, useRef } from 'react';
import './FloatingWaveform.css';
import { useAudioRecording } from '../../hooks/useAudioRecording';
import { WarningToast } from './WarningToast';
import { ProcessingToast } from './ProcessingToast';
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
        setLimitReached,
        isTranscribing
    } = useAudioRecording();

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [isFullscreen, setIsFullscreen] = useState(false);
    const [pushToTalkKey, setPushToTalkKey] = useState<string>('Fn');
    const pushToTalkKeyRef = useRef('Fn');

    useEffect(() => {
        pushToTalkKeyRef.current = pushToTalkKey;
    }, [pushToTalkKey]);

    const isShortcutRecordingRef = useRef(false);

    useEffect(() => {
        // Listen for shortcut recording state from other windows/modals
        const handleStateChange = (_event: any, isRecording: boolean) => {
            isShortcutRecordingRef.current = isRecording;
        };

        const removeListener = (window as any).electron.ipcRenderer.on('shortcut-recording-state-changed', handleStateChange);
        return () => {
            if (removeListener) removeListener();
        };
    }, []);

    // Processing Toast Logic
    const [processingVisible, setProcessingVisible] = useState(false);
    const processingTimerRef = useRef<NodeJS.Timeout | null>(null);
    const minDurationTimerRef = useRef<NodeJS.Timeout | null>(null);
    const showTimeRef = useRef<number>(0);

    useEffect(() => {
        if (isTranscribing) {
            // Start timer to SHoW toast
            processingTimerRef.current = setTimeout(() => {
                setProcessingVisible(true);
                showTimeRef.current = Date.now();
            }, 2000);
        } else {
            // Processing finished
            // 1. Cancel the start timer if it hasn't fired yet
            if (processingTimerRef.current) {
                clearTimeout(processingTimerRef.current);
                processingTimerRef.current = null;
            }

            // 2. If it WAS showing, ensure it stays for at least 1s
            if (processingVisible) {
                const elapsed = Date.now() - showTimeRef.current;
                const MIN_DURATION = 1000;
                const remaining = MIN_DURATION - elapsed;

                if (remaining > 0) {
                    minDurationTimerRef.current = setTimeout(() => {
                        setProcessingVisible(false);
                    }, remaining);
                } else {
                    setProcessingVisible(false);
                }
            } else {
                // Was not showing (or cancelled before show), so ensure hidden
                setProcessingVisible(false);
            }
        }

        return () => {
            if (processingTimerRef.current) {
                clearTimeout(processingTimerRef.current);
            }
            if (minDurationTimerRef.current) {
                clearTimeout(minDurationTimerRef.current);
            }
        };
    }, [isTranscribing, processingVisible]);

    // Load Settings & Check Permissions
    const [showFlowBarAlways, setShowFlowBarAlways] = useState(false);

    useEffect(() => {
        const loadSettings = async () => {
            try {
                if ((window as any).electron && (window as any).electron.ipcRenderer) {
                    const settings = await (window as any).electron.ipcRenderer.getAllSettings();
                    if (settings) {
                        if (settings.pushToTalkKey) {
                            setPushToTalkKey(settings.pushToTalkKey);
                        }
                        if (settings.showFlowBarAlways !== undefined) {
                            setShowFlowBarAlways(settings.showFlowBarAlways);
                        }
                    }
                }
            } catch (err) {
                console.error("Failed to load settings in Waveform:", err);
            }
        };

        const checkPermissions = async () => {
            try {
                if ((window as any).electron && (window as any).electron.ipcRenderer) {
                    const acc = await (window as any).electron.ipcRenderer.checkAccessibility();
                    console.log('Accessibility Permission Status:', acc);
                    if (!acc) {
                        console.log('Requesting accessibility permissions...');
                        await (window as any).electron.ipcRenderer.requestAccessibility();
                    }
                }
            } catch (err) {
                console.error("Failed to check permissions:", err);
            }
        };

        loadSettings();
        checkPermissions();

        // Listen for setting changes
        const handleSettingChanged = (_event: any, key: string, value: any) => {
            if (key === 'showFlowBarAlways') {
                setShowFlowBarAlways(value);
            }
            if (key === 'pushToTalkKey') {
                setPushToTalkKey(value);
            }
        };

        const removeListener = (window as any).electron?.ipcRenderer.on('setting-changed', handleSettingChanged);
        return () => {
            if (removeListener) removeListener();
        }
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

    // Block arrow keys globally
    useEffect(() => {
        const blockArrowKeys = (e: KeyboardEvent) => {
            if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
                e.preventDefault();
                e.stopPropagation();
                e.stopImmediatePropagation();
            }
        };

        // Add listener at capture phase to intercept before other handlers
        document.addEventListener('keydown', blockArrowKeys, true);
        document.addEventListener('keyup', blockArrowKeys, true);

        return () => {
            document.removeEventListener('keydown', blockArrowKeys, true);
            document.removeEventListener('keyup', blockArrowKeys, true);
        };
    }, []);

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
                if (!isRecordingRef.current && !isShortcutRecordingRef.current) {
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

    const [isHovered, setIsHovered] = useState(false);

    const handleMouseEnter = () => {
        setIsHovered(true);
        (window as any).electron.ipcRenderer.send('set-ignore-mouse-events', false)
    }

    const handleMouseLeave = () => {
        setIsHovered(false);
        (window as any).electron.ipcRenderer.send('set-ignore-mouse-events', true, { forward: true })
    }

    const handleWrapperWheel = (e: React.WheelEvent) => {
        // Prevent scroll events from being processed
        e.preventDefault();
        e.stopPropagation();
    };

    return (
        <div
            className="floating-waveform-wrapper"
            onWheel={handleWrapperWheel}
        >
            <div
                className={`orb-container ${warningVisible ? 'has-warning' : ''}`}
                onMouseEnter={handleMouseEnter}
                onMouseLeave={handleMouseLeave}
            >
                {(isHovered || showFlowBarAlways) && <HoverHint shortcutKey={pushToTalkKey} />}

                <WarningToast
                    visible={warningVisible}
                    onClose={() => setWarningVisible(false)}
                />

                <LimitToast
                    visible={limitReached}
                    onClose={() => setLimitReached(false)}
                />

                <ProcessingToast
                    visible={processingVisible}
                    onClose={() => setProcessingVisible(false)}
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
