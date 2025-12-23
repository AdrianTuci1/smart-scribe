import React, { useState } from 'react';
import { WelcomeStep } from './WelcomeStep';
import { AccessibilityStep } from './AccessibilityStep';
import { MicrophoneStep } from './MicrophoneStep';
import { DomainSelectionStep } from './DomainSelectionStep';
import { PlaceholderStep } from './PlaceholderStep';

interface OnboardingViewProps {
    onComplete: () => void;
}

export const OnboardingView: React.FC<OnboardingViewProps> = ({ onComplete }) => {
    const [currentStep, setCurrentStep] = useState(0);
    const [selectedDomains, setSelectedDomains] = useState<Set<string>>(new Set());

    const nextStep = () => setCurrentStep(prev => prev + 1);

    switch (currentStep) {
        case 0:
            return <WelcomeStep onNext={nextStep} />;
        case 1:
            return <AccessibilityStep onNext={nextStep} />;
        case 2:
            return <MicrophoneStep onNext={nextStep} />;
        case 3:
            return (
                <DomainSelectionStep
                    selectedDomains={selectedDomains}
                    setSelectedDomains={setSelectedDomains}
                    onNext={nextStep}
                />
            );
        case 4:
            return <PlaceholderStep title="Dictation Test" onNext={nextStep} />;
        case 5:
            return <PlaceholderStep title="Setup Complete" onNext={onComplete} />;
        default:
            return null;
    }
};
