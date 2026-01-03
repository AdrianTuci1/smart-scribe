import React, { useState, useMemo } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { Plus } from 'lucide-react';
import { LANGUAGES } from '../../data/languages';
import { LanguageModal } from '../../components/Shared/LanguageModal/LanguageModal';
import './LanguageSelectionStep.css';

interface LanguageSelectionStepProps {
    onNext: () => void;
    onBack?: () => void;
    currentStep?: number;
    totalSteps?: number;
    selectedIds: Set<string>;
    onToggle: (id: string) => void;
    visualImage?: string;
}

export const LanguageSelectionStep: React.FC<LanguageSelectionStepProps> = ({
    onNext,
    onBack,
    currentStep,
    totalSteps,
    selectedIds,
    onToggle,
    visualImage
}) => {
    const [isModalOpen, setIsModalOpen] = useState(false);

    const selectedLanguages = useMemo(() => {
        return LANGUAGES.filter(l => selectedIds.has(l.id));
    }, [selectedIds]);

    const VisualCard = (
        <div className="language-visual-card">
            <h3 className="language-visual-title">Your selected language</h3>
            <div className="selected-languages-display">
                <div className="language-tag-group">
                    {selectedLanguages.map(lang => (
                        <div key={lang.id} className="language-pill">
                            <span>{lang.label}</span>
                        </div>
                    ))}
                    <button className="add-language-btn-small" onClick={() => setIsModalOpen(true)}>
                        <Plus size={16} />
                    </button>
                </div>
            </div>
            <div className="language-card-actions">
                <button className="change-lang-btn" onClick={() => setIsModalOpen(true)}>
                    Change languages
                </button>
                <button className="continue-lang-btn" onClick={onNext}>
                    Continue
                </button>
            </div>
        </div>
    );

    return (
        <>
            <OnboardingLayout
                currentStep={currentStep}
                totalSteps={totalSteps}
                showVisual={true}
                visualContent={VisualCard}
                visualImage={visualImage}
            >
                <div className="language-selection-container">
                    <button
                        className="back-button-simple"
                        onClick={onBack}
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

                    <h1 className="language-step-title">Set the language(s) you speak</h1>
                    <p className="language-step-subtitle">Smartscribe works in 100+ languages.</p>
                    <p className="language-step-description">
                        Select all the languages you speak or let Smartscribe detect them automatically.
                    </p>
                </div>
            </OnboardingLayout>

            <LanguageModal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                selectedIds={selectedIds}
                onToggle={onToggle}
            />
        </>
    );
};
