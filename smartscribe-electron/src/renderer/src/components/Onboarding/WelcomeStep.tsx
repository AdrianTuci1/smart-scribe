import React from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import './WelcomeStep.css';

interface WelcomeStepProps {
    onNext: () => void;
}

export const WelcomeStep: React.FC<WelcomeStepProps> = ({ onNext }) => {
    return (
        <OnboardingLayout>
            <div className="welcome-container">
                <h1 className="welcome-title">Welcome to SmartScribe</h1>
                <p className="welcome-description">
                    Your AI-powered transcription assistant.
                </p>
                <button
                    onClick={onNext}
                    className="welcome-button"
                >
                    Get Started
                </button>
            </div>
        </OnboardingLayout>
    );
};
