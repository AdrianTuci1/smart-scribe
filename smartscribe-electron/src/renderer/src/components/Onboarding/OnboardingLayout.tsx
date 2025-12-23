import React from 'react';
import './OnboardingLayout.css';

interface OnboardingLayoutProps {
    children: React.ReactNode;
}

export const OnboardingLayout: React.FC<OnboardingLayoutProps> = ({ children }) => {
    return (
        <div className="onboarding-container">
            {children}
        </div>
    );
};
