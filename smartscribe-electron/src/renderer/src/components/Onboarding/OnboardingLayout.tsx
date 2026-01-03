import React, { useState } from 'react';
import './OnboardingLayout.css';
import { motion } from 'framer-motion';
import { HelpCircle, ChevronRight } from 'lucide-react';
import { TicketModal } from '../Shared/TicketModal';

interface OnboardingLayoutProps {
    children: React.ReactNode;
    showVisual?: boolean;
    visualImage?: string;
    visualContent?: React.ReactNode;
    onSkip?: () => void; // Keep prop if used by QuestionStep for functional skip, but remove the Dev button
    currentStep?: number;
    totalSteps?: number;
}

export const OnboardingLayout: React.FC<OnboardingLayoutProps> = ({
    children,
    showVisual = false,
    visualImage,
    visualContent,
    onSkip,
    currentStep = 1,
    totalSteps = 6
}) => {
    const [showTicketModal, setShowTicketModal] = useState(false);

    // Map currentStep (1-6) to Breadcrumb Setup
    const steps = ['SIGN IN', 'PERMISSIONS', 'SET UP', 'LEARN'];
    let currentBreadcrumbIndex = 0;
    // 0=SignIn
    // 1-3=Questions (Group with Permissions or Sign In? Let's group with Permissions for flow)
    // 4=Language Selection (Permissions)
    // 5=DataControl (Permissions)
    // 6=Permissions (Permissions)
    if (currentStep >= 1 && currentStep <= 6) currentBreadcrumbIndex = 1; // Permissions
    // 7=MicTest (Set Up)
    // 8=ShortcutTest (Set Up)
    // 9=InteractiveLearn (Set Up)
    if (currentStep >= 7 && currentStep <= 9) currentBreadcrumbIndex = 2; // Set Up
    // 10=Free Trial (Learn)
    // 11=Referral (Learn)
    if (currentStep >= 10) currentBreadcrumbIndex = 3; // Learn

    return (
        <div className="onboarding-viewport">
            {/* Header with Progress */}
            <div className="onboarding-header">
                <div className="breadcrumbs">
                    {steps.map((step, index) => (
                        <React.Fragment key={step}>
                            <div className={`crumb-item ${index === currentBreadcrumbIndex ? 'active' : ''}`}>
                                <span className={`crumb-text ${index > currentBreadcrumbIndex ? 'future' : ''}`}>{step}</span>
                            </div>
                            {index < steps.length - 1 && (
                                <ChevronRight className="crumb-separator" size={12} />
                            )}
                        </React.Fragment>
                    ))}
                </div>
                {/* Simplified header logic or just a progress bar */}
                <div className="step-progress-bar">
                    <div
                        className="progress-fill"
                        style={{ width: `${(currentStep / totalSteps) * 100}%` }}
                    />
                </div>
            </div>

            <div className="onboarding-split-container">
                {/* Left Side - Content */}
                <div className={`onboarding-content-side ${!showVisual ? 'full-width' : ''}`}>
                    <motion.div
                        className="content-wrapper"
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ duration: 0.4 }}
                    >
                        {children}
                    </motion.div>

                    <div className="help-button-wrapper">
                        <button className="help-btn" onClick={() => setShowTicketModal(true)}>
                            <HelpCircle size={14} /> Help
                        </button>
                    </div>
                </div>

                {/* Right Side - Visual */}
                {/* Right Side - Visual */}
                {showVisual && (
                    <div className="onboarding-visual-side">
                        {visualImage && (
                            <img src={visualImage} alt="Visual" className="visual-image" />
                        )}

                        {visualContent && (
                            <div className="visual-content-overlay">
                                {visualContent}
                            </div>
                        )}

                        {!visualImage && !visualContent && (
                            <div className="visual-placeholder" />
                        )}

                        {/* Dev Skip Button Removed */}
                    </div>
                )}
            </div>

            <TicketModal
                isOpen={showTicketModal}
                onClose={() => setShowTicketModal(false)}
            />
        </div>
    );
};
