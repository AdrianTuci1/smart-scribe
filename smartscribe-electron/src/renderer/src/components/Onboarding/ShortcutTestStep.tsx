import React, { useEffect, useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { Globe } from 'lucide-react';
import './ShortcutTestStep.css';
import './MicTestStep.css'; // Reuse button styles

interface ShortcutTestStepProps {
    onNext: () => void;
    onBack: () => void;
    visualImage?: string;
}

export const ShortcutTestStep: React.FC<ShortcutTestStepProps> = ({ onNext, onBack, visualImage }) => {
    const [isPressed, setIsPressed] = useState(false);
    const [targetShortcut, setTargetShortcut] = useState<string>('Fn');
    const [isRecording, setIsRecording] = useState(false);

    useEffect(() => {
        // Listen to IPC event
        const electron = (window as any).electron;
        let unsubscribe: (() => void) | undefined;

        if (electron && electron.ipcRenderer) {
            unsubscribe = electron.ipcRenderer.on('global-key-event', (data: any) => {
                const { type, modifiers, keyCode, chars } = data;

                // Construct the current shortcut string from event data
                let currentEventString = '';
                const parts = [...modifiers];

                // Handle modifers only (like Fn)
                if (type === 'flagsChanged' && parts.length > 0) {
                    currentEventString = parts.join('+');
                }
                // Handle keydown
                else if (type === 'keydown') {
                    let keyName = chars;
                    if (!keyName && keyCode === 49) keyName = 'Space';
                    if (keyName) {
                        currentEventString = [...parts, keyName].join('+');
                    }
                }

                // 1. RECORDING MODE
                if (isRecording) {
                    if (type === 'keyup') return; // Ignore keyups during record
                    // If we have a valid string, update the target
                    if (currentEventString) {
                        setTargetShortcut(currentEventString);
                        // If it's a complete press (e.g. standard key or modifier), we could stop recording?
                        // For modifiers like Fn, it's flagsChanged. 
                        // To make it easy, let's keep it 'live' while recording,
                        // user clicks 'Confirm' or we auto-stop? 
                        // Settings flow usually waits for release or assumes last combo.
                        // Let's click "No, change" -> turns into "Listening...". 
                        // They press keys. The label updates. 
                        // They click "Save/Confirm" or click away? 
                        // The existing UI has "Yes" (next) and "No, change". 
                        // Let's click "No, change" -> turns into "Listening...". 
                        // Press key -> Updates target -> Exits recording immediately?
                        // That might be too fast for combos.
                        // Let's auto-exit only on valid keydown? Fn is flagsChanged.
                        // Let's manually exit recording or check if keys are released?
                        setIsRecording(false);
                    }
                    return;
                }

                // 2. TESTING MODE (Not recording)
                // Reset press state on keyup/flags-release
                if (type === 'keyup' || (type === 'flagsChanged' && modifiers.length === 0)) {
                    setIsPressed(false);
                    return;
                }

                // Check match
                if (currentEventString === targetShortcut) {
                    setIsPressed(true);
                } else {
                    // Specific check for "Fn" if modifiers has it
                    if (targetShortcut === 'Fn' && modifiers.includes('Fn')) {
                        setIsPressed(true);
                    }
                }
            });
        }

        // Cleanup
        return () => {
            if (unsubscribe) unsubscribe();
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [isRecording, targetShortcut]);

    const handleConfirm = async () => {
        const electron = (window as any).electron;
        try {
            if (electron && electron.ipcRenderer && targetShortcut) {
                await electron.ipcRenderer.invoke('set-setting', 'pushToTalkKey', targetShortcut);
            }
        } catch (error) {
            console.error('Failed to save shortcut setting:', error);
        } finally {
            onNext();
        }
    };

    const VisualizerCard = (
        <div className="shortcut-visual-card">
            <h3 className="mic-card-title">Does the button turn purple while pressing it?</h3>

            <div className="shortcut-key-display">
                <div
                    className={`key-cap ${isPressed ? 'pressed' : ''} ${isRecording ? 'recording' : ''}`}
                    onClick={() => isRecording && setIsRecording(false)} // Allow cancelling record by click
                >
                    <span className="key-label">
                        {isRecording ? 'Press key...' : targetShortcut}
                    </span>
                    <Globe size={20} className="key-icon" />
                </div>
            </div>

            <div className="mic-actions">
                <button
                    className="change-mic-button"
                    onClick={() => setIsRecording(true)}
                    disabled={isRecording}
                >
                    {isRecording ? 'Recording...' : 'No, change shortcut'}
                </button>
                <button className="confirm-mic-button" onClick={handleConfirm}>Yes</button>
            </div>
        </div>
    );

    return (
        <OnboardingLayout
            currentStep={5}
            totalSteps={8}
            showVisual={true}
            visualContent={VisualizerCard}
            visualImage={visualImage}
        >
            <div className="shortcut-test-container">
                <button
                    className="back-button-simple"
                    onClick={onBack}
                    style={{
                        alignSelf: 'flex-start',
                        background: 'none',
                        border: 'none',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        color: '#6b7280',
                        cursor: 'pointer',
                        marginBottom: '24px',
                        fontSize: '14px'
                    }}
                >
                    ← Back
                </button>

                <h1 className="shortcut-test-title">Press the keyboard shortcut to test it out</h1>
                <p className="shortcut-test-subtitle">
                    We recommend the <span className="shortcut-code">Fn</span> key at the bottom left of the keyboard.
                </p>
            </div>
        </OnboardingLayout>
    );
};
