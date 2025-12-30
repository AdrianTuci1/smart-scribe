import React, { useEffect, useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { Globe } from 'lucide-react';
import './ShortcutTestStep.css';
import './MicTestStep.css'; // Reuse button styles

interface ShortcutTestStepProps {
    onNext: () => void;
}

export const ShortcutTestStep: React.FC<ShortcutTestStepProps> = ({ onNext }) => {
    const [isPressed, setIsPressed] = useState(false);

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            // Check for 'fn' key (not always standard) or any key for demo
            // 'Fn' key often doesn't trigger keydown, but 'Meta', 'Control', or 'Alt' do.
            // Mac functionality often uses Globe/Fn.
            // Let's light up on ANY key for now, or specific ones.
            console.log('Key pressed:', e.key);
            setIsPressed(true);
        };

        const handleKeyUp = () => {
            setIsPressed(false);
        };

        window.addEventListener('keydown', handleKeyDown);
        window.addEventListener('keyup', handleKeyUp);

        // Listen to IPC event if available for global shortcut
        const electron = (window as any).electron;
        let unsubscribe: (() => void) | undefined;

        if (electron && electron.ipcRenderer) {
            unsubscribe = electron.ipcRenderer.on('shortcut-pressed', () => {
                setIsPressed(true);
                setTimeout(() => setIsPressed(false), 200); // Pulse it
            });
        }

        return () => {
            window.removeEventListener('keydown', handleKeyDown);
            window.removeEventListener('keyup', handleKeyUp);
            if (unsubscribe) {
                unsubscribe();
            }
        };
    }, []);

    const VisualizerCard = (
        <div className="shortcut-visual-card">
            <h3 className="mic-card-title">Does the button turn purple while pressing it?</h3>

            <div className="shortcut-key-display">
                <div className={`key-cap ${isPressed ? 'pressed' : ''}`}>
                    <span className="key-label">fn</span>
                    <Globe size={20} className="key-icon" />
                </div>
            </div>

            <div className="mic-actions">
                <button className="change-mic-button">No, change shortcut</button>
                <button className="confirm-mic-button" onClick={onNext}>Yes</button>
            </div>
        </div>
    );

    return (
        <OnboardingLayout
            currentStep={5}
            totalSteps={8}
            showVisual={true}
            visualContent={VisualizerCard}
        >
            <div className="shortcut-test-container">
                <button
                    className="back-button-simple"
                    onClick={() => { }}
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
                    We recommend the <span className="shortcut-code">fn</span> key at the bottom left of the keyboard.
                </p>
            </div>
        </OnboardingLayout>
    );
};
