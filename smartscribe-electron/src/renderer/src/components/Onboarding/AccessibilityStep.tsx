import React, { useEffect, useState } from 'react';
import './AccessibilityStep.css';
import { OnboardingLayout } from './OnboardingLayout';
import { CheckCircle, Keyboard, ArrowRight, ShieldAlert } from 'lucide-react';
import { motion } from 'framer-motion';

interface AccessibilityStepProps {
    onNext: () => void;
}

export const AccessibilityStep: React.FC<AccessibilityStepProps> = ({ onNext }) => {
    const [hasPermission, setHasPermission] = useState(false);
    const [isChecking, setIsChecking] = useState(false);
    const pollInterval = React.useRef<NodeJS.Timeout | null>(null);

    // Cleanup polling on unmount
    useEffect(() => {
        return () => {
            if (pollInterval.current) {
                clearInterval(pollInterval.current);
            }
        };
    }, []);

    const startPolling = () => {
        if (pollInterval.current) return;

        pollInterval.current = setInterval(async () => {
            try {
                const granted = await (window as any).electron.ipcRenderer.checkAccessibility();
                if (granted) {
                    if (pollInterval.current) clearInterval(pollInterval.current);
                    setHasPermission(true);
                    setIsChecking(false);
                    setTimeout(onNext, 1000);
                }
            } catch (error) {
                console.error('Polling check failed:', error);
            }
        }, 1000);
    };

    const checkPermission = async () => {
        setIsChecking(true);
        try {
            // Trigger the explicit request (opens system dialog)
            const granted = await (window as any).electron.ipcRenderer.requestAccessibility();

            if (granted) {
                setHasPermission(true);
                setIsChecking(false);
                setTimeout(onNext, 1000);
            } else {
                // Not granted immediately, start polling for external change
                startPolling();
            }
        } catch (error) {
            console.error('Failed to check accessibility:', error);
            setIsChecking(false);
        }
    };

    useEffect(() => {
        const initCheck = async () => {
            const granted = await (window as any).electron.ipcRenderer.checkAccessibility();
            setHasPermission(granted);
            if (granted) {
                onNext();
            }
        };
        initCheck();
    }, [onNext]);

    return (
        <OnboardingLayout>
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="accessibility-container"
            >
                <div className="accessibility-icon-container">
                    <Keyboard size={32} className="keyboard-icon" />
                </div>

                <h1 className="accessibility-title">Enable Accessibility</h1>
                <p className="accessibility-description">
                    SmartScribe needs accessibility permissions to detect where to insert text and handle shortcuts.
                </p>

                {!hasPermission ? (
                    <div className="accessibility-actions">
                        <button
                            onClick={checkPermission}
                            disabled={isChecking}
                            className="grant-button"
                        >
                            {isChecking ? 'Checking...' : 'Grant Permission'}
                        </button>

                        <div className="system-settings-note">
                            <ShieldAlert size={14} className="shield-icon" />
                            <span>System Settings will open</span>
                        </div>
                    </div>
                ) : (
                    <motion.div
                        initial={{ scale: 0.9, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }}
                        className="permission-granted"
                    >
                        <CheckCircle size={32} className="check-icon" />
                        <span className="permission-granted-text">Permission Granted</span>
                    </motion.div>
                )}

                {!hasPermission && (
                    <button
                        onClick={onNext}
                        className="skip-link"
                    >
                        Skip for development <ArrowRight size={14} className="arrow-icon" />
                    </button>
                )}
            </motion.div>
        </OnboardingLayout>
    );
};
