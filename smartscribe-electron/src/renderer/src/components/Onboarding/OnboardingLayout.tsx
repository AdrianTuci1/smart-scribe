import React from 'react';
import './OnboardingLayout.css';
import { motion } from 'framer-motion';
import { HelpCircle, ChevronRight } from 'lucide-react';

interface OnboardingLayoutProps {
    children: React.ReactNode;
    showVisual?: boolean;
    visualImage?: string;
    visualContent?: React.ReactNode;
    onSkip?: () => void;
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
    // Map currentStep (1-6) to Breadcrumb Setup
    const steps = ['SIGN IN', 'PERMISSIONS', 'SET UP', 'LEARN'];
    let currentBreadcrumbIndex = 0;
    // 0=SignIn
    // 1-3=Questions (Group with Permissions or Sign In? Let's group with Permissions for flow)
    // 4=DataControl (Permissions)
    // 5=Permissions (Permissions)
    if (currentStep >= 1 && currentStep <= 5) currentBreadcrumbIndex = 1; // Permissions
    // 6=MicTest (Set Up)
    // 7=ShortcutTest (Set Up)
    if (currentStep >= 6 && currentStep <= 7) currentBreadcrumbIndex = 2; // Set Up
    // 8=Learn
    if (currentStep >= 8) currentBreadcrumbIndex = 3; // Learn

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
                        <button className="help-btn"><HelpCircle size={14} /> Help</button>
                    </div>
                </div>

                {/* Right Side - Visual */}
                {showVisual && (
                    <div className="onboarding-visual-side">
                        {visualContent ? (
                            visualContent
                        ) : visualImage ? (
                            <img src={visualImage} alt="Visual" className="visual-image" />
                        ) : (
                            <div className="visual-placeholder" />
                        )}

                        {/* Dev Skip Button */}
                        <button onClick={onSkip} className="dev-skip-button">
                            Skip (Dev)
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
};
