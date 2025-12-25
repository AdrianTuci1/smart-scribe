import React, { useEffect, useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { Mic, CheckCircle } from 'lucide-react';
import './MicrophoneStep.css';
import './AccessibilityStep.css'; // Reusing common styles

interface MicrophoneStepProps {
    onNext: () => void;
}

export const MicrophoneStep: React.FC<MicrophoneStepProps> = ({ onNext }) => {
    const [hasPermission, setHasPermission] = useState(false);

    const requestPermission = async () => {
        try {
            const granted = await (window as any).electron.ipcRenderer.requestMicrophone();
            setHasPermission(granted);
            if (granted) {
                setTimeout(onNext, 1000);
            }
        } catch (error) {
            console.error('Failed to request microphone:', error);
        }
    };

    useEffect(() => {
        const initCheck = async () => {
            const status = await (window as any).electron.ipcRenderer.checkMicrophone();
            setHasPermission(status === 'granted');
        };
        initCheck();
    }, []);

    return (
        <OnboardingLayout>
            <div className="microphone-container">
                <Mic className="mic-icon" />

                <h1 className="accessibility-title">Microphone Access</h1>
                <p className="accessibility-description">
                    SmartScribe needs access to your microphone to capture your voice for transcription.
                </p>

                <button
                    onClick={requestPermission}
                    className="grant-button"
                    style={{ backgroundColor: hasPermission ? undefined : '#ef4444' }} // Red color for mic override if needed, or stick to default
                    disabled={hasPermission}
                >
                    {hasPermission ? 'Access Granted' : 'Enable Microphone'}
                </button>

                {hasPermission && (
                    <div className="permission-status status-granted">
                        <CheckCircle size={16} />
                        <span>Microphone Ready</span>
                    </div>
                )}

                {!hasPermission && (
                    <div className="skip-container">
                        <button onClick={onNext} className="skip-link-mic">Skip for now (Dev)</button>
                    </div>
                )}
            </div>
        </OnboardingLayout>
    );
};
