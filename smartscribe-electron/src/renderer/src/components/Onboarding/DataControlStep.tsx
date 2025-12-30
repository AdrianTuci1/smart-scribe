import React, { useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { CheckCircle2 } from 'lucide-react';
import { motion } from 'framer-motion';
import './DataControlStep.css';

interface DataControlStepProps {
    onNext: () => void;
}

export const DataControlStep: React.FC<DataControlStepProps> = ({ onNext }) => {
    const [selectedMode, setSelectedMode] = useState<'improve' | 'privacy'>('improve');

    return (
        <OnboardingLayout
            currentStep={4} // This is functionally step 4 after the 3 question steps (which are index 1,2,3 in OnboardingView logic, so let's check that logic later)
            // Actually, OnboardingView uses 0-based index. 
            // 0: Login
            // 1: Source
            // 2: Role
            // 3: Usage
            // 4: THIS STEP
            totalSteps={8}
            showVisual={true}
            visualImage="" // We will need the specific circular lock image if available, else placeholder
        >
            <div className="data-control-container">
                <button
                    className="back-button-simple"
                    onClick={() => { }} // TODO: Add onBack prop if needed, or handle in parent
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

                <h1 className="data-control-title">You control your data</h1>

                <div
                    className={`data-option-card ${selectedMode === 'improve' ? 'selected' : ''}`}
                    onClick={() => setSelectedMode('improve')}
                >
                    <div className="data-option-header">
                        <span className="data-option-title">Help improve Smartscribe</span>
                        {selectedMode === 'improve' && <CheckCircle2 size={20} className="check-icon" fill="#10b981" color="white" />}
                    </div>
                    <p className="data-option-description">
                        To make Smartscribe better, this option lets us collect your audio, transcript, and edits to evaluate, train and improve Smartscribe's features and AI models
                    </p>
                </div>

                <div
                    className={`data-option-card ${selectedMode === 'privacy' ? 'selected' : ''}`}
                    onClick={() => setSelectedMode('privacy')}
                >
                    <div className="data-option-header">
                        <span className="data-option-title">Privacy Mode</span>
                        {selectedMode === 'privacy' && <CheckCircle2 size={20} className="check-icon" fill="#10b981" color="white" />}
                    </div>
                    <p className="data-option-description">
                        If you enable Privacy Mode, none of your dictation data will be stored or used for model training by us or any third party.
                    </p>
                </div>

                <p className="privacy-note">
                    You can always change this later in settings.<br />
                    <strong>Read more here.</strong>
                </p>

                <div className="continue-button-container">
                    <button className="continue-button" onClick={onNext}>
                        Continue
                    </button>
                </div>
            </div>
        </OnboardingLayout>
    );
};
