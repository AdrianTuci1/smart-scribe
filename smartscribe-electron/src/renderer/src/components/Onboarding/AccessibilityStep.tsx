import React, { useEffect, useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { CheckCircle, XCircle, Keyboard } from 'lucide-react';
import './AccessibilityStep.css';

interface AccessibilityStepProps {
    onNext: () => void;
}

export const AccessibilityStep: React.FC<AccessibilityStepProps> = ({ onNext }) => {
    const [hasPermission, setHasPermission] = useState(false);
    const [isChecking, setIsChecking] = useState(false);

    const checkPermission = async () => {
        setIsChecking(true);
        try {
            const granted = await window.electron.ipcRenderer.requestAccessibility();
            setHasPermission(granted);
            if (granted) {
                // Auto advance after a short delay if granted
                setTimeout(onNext, 1000);
            }
        } catch (error) {
            console.error('Failed to check accessibility:', error);
        } finally {
            setIsChecking(false);
        }
    };

    useEffect(() => {
        // Initial check without prompting
        const initCheck = async () => {
            const granted = await window.electron.ipcRenderer.checkAccessibility();
            setHasPermission(granted);
        };
        initCheck();
    }, []);

    return (
        <OnboardingLayout>
            <div className="flex flex-col items-center justify-center h-full">
                <Keyboard className="accessibility-icon" />

                <h1 className="welcome-title">Accessibility Access</h1>
                <p className="welcome-description">
                    SmartScribe needs accessibility permissions to detect where to insert text and to handle global shortcuts.
                </p>

                <button
                    onClick={checkPermission}
                    className="welcome-button"
                    disabled={hasPermission}
                >
                    {hasPermission ? 'Permission Granted' : 'Grant Permission'}
                </button>

                {hasPermission && (
                    <div className="permission-status status-granted">
                        <CheckCircle size={16} />
                        <span>Access Granted</span>
                    </div>
                )}

                {!hasPermission && (
                    <div className="mt-4">
                        <button onClick={onNext} className="text-gray-400 text-sm underline">Skip for now (Dev)</button>
                    </div>
                )}
            </div>
        </OnboardingLayout>
    );
};
