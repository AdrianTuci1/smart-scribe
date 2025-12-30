import React, { useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import './FreeTrialStep.css';
import { ChevronLeft } from 'lucide-react';

interface FreeTrialStepProps {
    onNext: () => void;
    onBack: () => void;
    currentStep?: number;
    totalSteps?: number;
}

export const FreeTrialStep: React.FC<FreeTrialStepProps> = ({
    onNext,
    onBack,
    currentStep,
    totalSteps
}) => {
    const [isTrialEnabled, setIsTrialEnabled] = useState(true);

    const VisualContent = (
        <div className="runner-visual">
            {/* Placeholder for the runner illustration. The user provided an image, but we don't have the SVG/PNG asset.
               I'll creating a simple CSS shape or text placeholder if image isn't available, 
               or reference an assets/runner.png if I were to download it. 
               For now, I'll use a placeholder div that suggests the illustration area. */}
            <div style={{ fontSize: '100px', textAlign: 'center' }}>
                🏃‍♀️✨
                <p style={{ fontSize: '18px', marginTop: '20px', color: '#666' }}>
                    (User illustration placeholder)
                </p>
            </div>
        </div>
    );

    return (
        <OnboardingLayout
            currentStep={currentStep}
            totalSteps={totalSteps}
            showVisual={true}
            visualContent={VisualContent}
        >
            <div className="free-trial-container">
                <button
                    className="back-button-simple"
                    onClick={onBack}
                >
                    <ChevronLeft size={16} /> Back
                </button>

                <div className="free-trial-content">
                    <span className="exclusive-offer-badge">EXCLUSIVE OFFER</span>

                    <h1 className="free-trial-title">
                        You've unlocked<br />
                        <em>unlimited words</em>
                    </h1>

                    <p className="free-trial-description">
                        Enjoy 2 weeks of unlimited access to Smartscribe Pro on us. No credit card required.
                    </p>

                    <div className="trial-card">
                        <div className="trial-toggle-row">
                            <span className="trial-toggle-label">Enable Free Pro Trial (no card required)</span>
                            <label className="trial-switch">
                                <input
                                    type="checkbox"
                                    checked={isTrialEnabled}
                                    onChange={(e) => setIsTrialEnabled(e.target.checked)}
                                />
                                <span className="trial-slider"></span>
                            </label>
                        </div>

                        <button className="claim-button" onClick={onNext}>
                            Claim my free trial
                        </button>
                    </div>

                    <p className="trial-fine-print">
                        Without a Smartscribe Pro trial, you'll start on Smartscribe Basic and will be limited to 2,000 words per week.
                    </p>
                </div>
            </div>
        </OnboardingLayout>
    );
};
