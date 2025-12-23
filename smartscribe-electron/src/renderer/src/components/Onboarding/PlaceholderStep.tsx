import React from 'react';
import { OnboardingLayout } from './OnboardingLayout';

interface StepProps {
    onNext: () => void;
    title: string;
}

export const PlaceholderStep: React.FC<StepProps> = ({ onNext, title }) => {
    return (
        <OnboardingLayout>
            <div className="flex flex-col items-center">
                <h1 className="text-2xl font-bold mb-4">{title}</h1>
                <button
                    onClick={onNext}
                    className="bg-blue-600 text-white px-6 py-2 rounded-full hover:bg-blue-700 transition"
                >
                    Next
                </button>
            </div>
        </OnboardingLayout>
    );
};
