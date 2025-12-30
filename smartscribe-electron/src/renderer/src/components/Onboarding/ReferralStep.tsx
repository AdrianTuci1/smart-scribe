import React, { useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import './ReferralStep.css';
import { ChevronLeft, Share2, Award, PartyPopper, Link as LinkIcon } from 'lucide-react';

interface ReferralStepProps {
    onComplete: () => void;
    onBack: () => void;
    currentStep?: number;
    totalSteps?: number;
}

export const ReferralStep: React.FC<ReferralStepProps> = ({
    onComplete,
    onBack,
    currentStep,
    totalSteps
}) => {
    const referralLink = "https://smartscribe.ai/r?TUCEAN1"; // Example from screenshot
    const [copied, setCopied] = useState(false);

    const handleCopy = () => {
        navigator.clipboard.writeText(referralLink);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const VisualContent = (
        <div className="gift-card-visual">
            <div className="gift-card">
                <div className="gift-card-wave"></div>
                <div className="gift-card-content">
                    <div className="gift-logo">
                        <span>|l|l| Smartscribe</span> <span className="pro-badge">Pro</span>
                    </div>
                    <div className="gift-text">Unlimited Words For 1 Month</div>
                    <div className="gift-pill">Gifted by Tucean</div>
                </div>
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
            <div className="referral-container">
                <button className="back-button-simple" onClick={onBack}>
                    <ChevronLeft size={16} /> Back
                </button>

                <div className="referral-header">
                    <h1 className="referral-title">
                        Give the magic of Smartscribe.<br />
                        Get a month of Pro.
                    </h1>
                </div>

                <div className="referral-how-it-works-title">How it works?</div>
                <ul className="referral-steps">
                    <li className="referral-step-item">
                        <div className="referral-icon"><Share2 size={20} /></div>
                        <span className="referral-text">Share your invite link</span>
                    </li>
                    <li className="referral-step-item">
                        <div className="referral-icon"><Award size={20} /></div>
                        <span className="referral-text">They sign up and get a <strong>free month of Pro!</strong></span>
                    </li>
                    <li className="referral-step-item">
                        <div className="referral-icon"><PartyPopper size={20} /></div>
                        <span className="referral-text">You get <strong>a free month</strong> when they<br />dictate 2,000 words!</span>
                    </li>
                </ul>

                <div className="referral-link-section-title">Your referral link</div>
                <div className="referral-link-box">
                    <div className="referral-input-wrapper">
                        <LinkIcon size={16} className="link-icon" />
                        <input type="text" readOnly value={referralLink} className="referral-input" />
                    </div>
                    <button className="copy-button" onClick={handleCopy}>
                        {copied ? "Copied" : "Copy"}
                    </button>
                </div>

                <button className="finish-button" onClick={onComplete}>
                    Finish
                </button>
            </div>
        </OnboardingLayout>
    );
};
