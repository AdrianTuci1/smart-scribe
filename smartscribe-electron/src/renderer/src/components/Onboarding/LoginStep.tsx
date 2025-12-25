import React, { useState } from 'react';
import './LoginStep.css';
import { OnboardingLayout } from './OnboardingLayout';
import { authService } from '../../services/auth';
import { ArrowRight, Globe } from 'lucide-react';
import { motion } from 'framer-motion';

interface LoginStepProps {
    onNext: () => void;
}

export const LoginStep: React.FC<LoginStepProps> = ({ onNext }) => {
    const [isLoading, setIsLoading] = useState(false);

    const handleBrowserLogin = async () => {
        setIsLoading(true);
        // Simulate waiting for auth or just trigger open
        try {
            await authService.signInWithWebBrowser();
            // In a real flow, we would wait for the callback (App.tsx handles deep link).
            // But for Onboarding, we might want to poll or wait?
            // For now, simpler: The deep link handler in App.tsx updates global state.
            // OnboardingView usually mounts/unmounts.
            // Let's assume user returns to app manually or via callback.
            // If we want to auto-advance on login, we'd need to listen to auth state changes here.
            // But user asked to "Skip".

            // NOTE: Since deep link handling is in App.tsx, this component might need a prop to know if auth succeeded.
            // For simplicity, we just trigger the browser opening.
        } catch (error) {
            console.error(error);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <OnboardingLayout>
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="login-container"
            >
                <div className="login-icon-container">
                    <Globe size={32} className="globe-icon" />
                </div>

                <h1 className="login-title">Welcome to Wispr Flow</h1>
                <p className="login-description">
                    Sync your voice notes across all your devices. Sign in to get started.
                </p>

                <button
                    onClick={handleBrowserLogin}
                    disabled={isLoading}
                    className="login-button"
                >
                    {isLoading ? <span>Opening Browser...</span> : (
                        <>
                            <span>Sign In with Browser</span>
                            <Globe size={18} />
                        </>
                    )}
                </button>

                <div className="divider-container">
                    <div className="divider-line-wrapper">
                        <div className="divider-line"></div>
                    </div>
                    <div className="divider-text-wrapper">
                        <span className="divider-text">Or</span>
                    </div>
                </div>

                <button
                    onClick={onNext}
                    className="skip-button"
                >
                    Skip for now <ArrowRight size={14} />
                </button>
            </motion.div>
        </OnboardingLayout>
    );
};
