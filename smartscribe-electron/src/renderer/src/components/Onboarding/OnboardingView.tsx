import React, { useState } from 'react';
import { LoginStep } from './LoginStep';
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
            return <LoginStep key="login" onNext={nextStep} />;
        case 1:
            return <AccessibilityStep key="access" onNext={nextStep} />;
        case 2:
            return <MicrophoneStep key="mic" onNext={nextStep} />;
        case 3:
            return (
                <DomainSelectionStep
                    key="domain"
                    selectedDomains={selectedDomains}
                    setSelectedDomains={setSelectedDomains}
                    onNext={nextStep}
                />
            );
        case 4:
            return <PlaceholderStep key="test" title="Dictation Test" onNext={nextStep} />;
        case 5:
            return <PlaceholderStep key="complete" title="Setup Complete" onNext={onComplete} />;
        default:
            return null;
    }
};
