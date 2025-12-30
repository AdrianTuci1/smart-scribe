import React from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import './QuestionStep.css';
import { ArrowRight, Check } from 'lucide-react';
import { motion } from 'framer-motion';

export interface Option {
    id: string;
    label: string;
    icon?: React.ReactNode;
}

interface QuestionStepProps {
    title: string;
    subtitle?: string;
    options: Option[];
    selected: Set<string>;
    onSelect: (id: string) => void;
    multiSelect?: boolean;
    onNext: () => void;
    onSkip?: () => void;
    onBack?: () => void;
    visualImage?: string;
    currentStep?: number;
    totalSteps?: number;
}

export const QuestionStep: React.FC<QuestionStepProps> = ({
    title,
    subtitle,
    options,
    selected,
    onSelect,
    multiSelect = false,
    onNext,
    onSkip,
    onBack,
    visualImage,
    currentStep,
    totalSteps
}) => {
    const handleOptionClick = (id: string) => {
        onSelect(id);
        if (!multiSelect) {
            // Auto advance for single select? Maybe not, keep explicit continue
        }
    };

    return (
        <OnboardingLayout
            showVisual={true}
            visualImage={visualImage}
            onSkip={onSkip}
            currentStep={currentStep}
            totalSteps={totalSteps}
        >
            <div className="question-content">
                {onBack && (
                    <button onClick={onBack} className="back-button">
                        ← Back
                    </button>
                )}

                <h1 className="question-title">{title}</h1>
                {subtitle && <p className="question-subtitle">{subtitle}</p>}

                <div className="options-grid">
                    {options.map((option) => {
                        const isSelected = selected.has(option.id);
                        return (
                            <button
                                key={option.id}
                                className={`option-button ${isSelected ? 'selected' : ''}`}
                                onClick={() => handleOptionClick(option.id)}
                            >
                                {option.icon && <span className="option-icon">{option.icon}</span>}
                                <span className="option-label">{option.label}</span>
                                {isSelected && multiSelect && <Check size={16} className="check-mark" />}
                            </button>
                        );
                    })}
                </div>

                <div className="actions-footer">
                    {onSkip && (
                        <button onClick={onSkip} className="skip-action">
                            Skip
                        </button>
                    )}

                    <button
                        onClick={onNext}
                        className="continue-button"
                        disabled={selected.size === 0 && !onSkip} // If skip implies optional, but often we want at least one or explicit skip
                    >
                        Continue
                    </button>
                </div>
            </div>
        </OnboardingLayout>
    );
};
