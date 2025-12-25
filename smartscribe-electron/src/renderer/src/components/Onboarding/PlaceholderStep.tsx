import React from 'react';
import { OnboardingLayout } from './OnboardingLayout';

import './PlaceholderStep.css';

interface StepProps {
    onNext: () => void;
    title: string;
}

export const PlaceholderStep: React.FC<StepProps> = ({ onNext, title }) => {
    return (
        <OnboardingLayout>
            <div className="placeholder-container">
                <h1 className="placeholder-title">{title}</h1>
                <button
                    onClick={onNext}
                    className="placeholder-button"
                >
                    Next
                </button>
            </div>
        </OnboardingLayout>
    );
};
