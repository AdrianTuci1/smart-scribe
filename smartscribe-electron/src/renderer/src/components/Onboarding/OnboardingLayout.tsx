import React from 'react';
import './OnboardingLayout.css';
import { motion } from 'framer-motion';

interface OnboardingLayoutProps {
    children: React.ReactNode;
}

export const OnboardingLayout: React.FC<OnboardingLayoutProps> = ({ children }) => {
    return (
        <div className="onboarding-viewport">
            <div className="onboarding-background">
                {/* Ambient Glows */}
                <div className="glow glow-top" />
                <div className="glow glow-bottom" />
            </div>

            <motion.div
                className="onboarding-content"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.5 }}
            >
                {children}
            </motion.div>
        </div>
    );
};
