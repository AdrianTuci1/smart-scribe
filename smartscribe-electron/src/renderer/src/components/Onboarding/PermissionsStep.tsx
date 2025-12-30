import React, { useEffect, useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { CheckCircle2, Info } from 'lucide-react';
import './PermissionsStep.css';

interface PermissionsStepProps {
    onNext: () => void;
}

export const PermissionsStep: React.FC<PermissionsStepProps> = ({ onNext }) => {
    const [accessibilityGranted, setAccessibilityGranted] = useState(false);
    const [microphoneGranted, setMicrophoneGranted] = useState(false);

    // Initial check
    useEffect(() => {
        const checkPermissions = async () => {
            try {
                const acc = await (window as any).electron.ipcRenderer.checkAccessibility();
                setAccessibilityGranted(acc);

                const mic = await (window as any).electron.ipcRenderer.checkMicrophone();
                setMicrophoneGranted(mic === 'granted');
            } catch (err) {
                console.error("Error checking permissions", err);
            }
        };
        checkPermissions();

        // Optional: Poll for accessibility if checking
        const interval = setInterval(async () => {
            const acc = await (window as any).electron.ipcRenderer.checkAccessibility();
            if (acc) setAccessibilityGranted(true);
        }, 2000);

        return () => clearInterval(interval);
    }, []);

    // Auto-advance if both granted? Maybe not, better to let user click Continue if there is one, or just wait.
    // The design doesn't explicitly show a "Continue" button, but usually there is one or it appears when done.
    // However, if both cards are done, maybe we show a "Next" button.

    // Actually, let's keep it simple: The user clicks "Allow", system dialog appears.
    // If both are true, we can auto-advance or show a button.
    // Let's add a "Continue" button that is enabled when both are true, or maybe just always there but highlights missing?
    // Let's assume we proceed once both are granted OR user manually advances (if optional). But they seem mandatory.

    const requestAccessibility = async () => {
        const granted = await (window as any).electron.ipcRenderer.requestAccessibility();
        if (granted) setAccessibilityGranted(true);
    };

    const requestMicrophone = async () => {
        const granted = await (window as any).electron.ipcRenderer.requestMicrophone();
        setMicrophoneGranted(granted);
    };

    const handleNext = () => {
        // Allow proceeding even if not all granted? Usually devs want to skip.
        onNext();
    };

    return (
        <OnboardingLayout
            currentStep={5}
            totalSteps={8}
            showVisual={true}
        // visualImage should highlight the settings window as in the screenshot
        >
            <div className="permissions-container">
                <button
                    className="back-button-simple"
                    onClick={() => { }} // TODO: Handle back
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

                <h1 className="permissions-title">Set up Flow on your computer</h1>

                {/* Accessibility Card */}
                <div className={`permission-card ${accessibilityGranted ? 'granted' : ''}`}>
                    <div className="permission-header">
                        <span className="permission-title">Allow Flow to insert spoken words</span>
                    </div>
                    <p className="permission-description">
                        This lets Flow put your spoken words in the right textbox
                    </p>
                    <div className="permission-action-row">
                        {!accessibilityGranted ? (
                            <>
                                <button className="allow-button" onClick={requestAccessibility}>Allow</button>
                                <Info size={16} className="info-icon" />
                            </>
                        ) : (
                            <div className="granted-badge">
                                <CheckCircle2 size={18} />
                                <span>Allowed</span>
                            </div>
                        )}
                    </div>
                </div>

                {/* Microphone Card */}
                <div className={`permission-card ${microphoneGranted ? 'granted' : ''}`}>
                    <div className="permission-header">
                        <span className="permission-title">Allow Flow to use your microphone</span>
                    </div>
                    {/* Description wasn't explicitly visible in screenshot for Mic, but good to have */}
                    <div className="permission-action-row" style={{ marginTop: '16px' }}>
                        {!microphoneGranted ? (
                            <button className="allow-button" onClick={requestMicrophone}>Allow Flow to use your microphone</button>
                        ) : (
                            <div className="granted-badge">
                                <CheckCircle2 size={18} />
                                <span>Allowed</span>
                            </div>
                        )}
                    </div>
                </div>

                {accessibilityGranted && microphoneGranted && (
                    <div className="continue-button-container" style={{ marginTop: 'auto' }}>
                        <button className="continue-button" onClick={handleNext}>
                            Continue
                        </button>
                    </div>
                )}

                {(!accessibilityGranted || !microphoneGranted) && (
                    <div className="skip-text" onClick={handleNext}>
                        Skip for now (Dev)
                    </div>
                )}

            </div>
        </OnboardingLayout>
    );
};
