import React from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { Stethoscope, Scale, Code as CodeIcon, Briefcase, GraduationCap, PenTool, MessageCircle } from 'lucide-react';
import './DomainSelectionStep.css';

interface DomainSelectionStepProps {
    onNext: () => void;
    selectedDomains: Set<string>;
    setSelectedDomains: React.Dispatch<React.SetStateAction<Set<string>>>;
}

const DOMAINS = [
    { id: 'Medical', label: 'Medical', icon: Stethoscope },
    { id: 'Legal', label: 'Legal', icon: Scale },
    { id: 'Technical/Coding', label: 'Technical/Coding', icon: CodeIcon },
    { id: 'Business', label: 'Business', icon: Briefcase },
    { id: 'Academic', label: 'Academic', icon: GraduationCap },
    { id: 'Creative Writing', label: 'Creative Writing', icon: PenTool },
    { id: 'General', label: 'General', icon: MessageCircle },
];

export const DomainSelectionStep: React.FC<DomainSelectionStepProps> = ({
    onNext,
    selectedDomains,
    setSelectedDomains
}) => {
    const toggleDomain = (domainId: string) => {
        setSelectedDomains(prev => {
            const next = new Set(prev);
            if (next.has(domainId)) {
                next.delete(domainId);
            } else {
                next.add(domainId);
            }
            return next;
        });
    };

    return (
        <OnboardingLayout>
            <div className="flex flex-col h-full w-full">
                <div className="domain-header">
                    <h1 className="domain-title">Tailor Your Experience</h1>
                    <p className="domain-description">
                        Select the domains you'll be writing in most often. This helps us optimize accurate terminology.
                    </p>
                </div>

                <div className="domain-grid custom-scrollbar">
                    {DOMAINS.map(({ id, label, icon: Icon }) => {
                        const isSelected = selectedDomains.has(id);
                        return (
                            <button
                                key={id}
                                onClick={() => toggleDomain(id)}
                                className={`domain-card ${isSelected ? 'selected' : ''}`}
                            >
                                <Icon className="domain-icon" />
                                <span className="domain-label">
                                    {label}
                                </span>
                            </button>
                        );
                    })}
                </div>

                <div className="domain-footer">
                    <button
                        onClick={onNext}
                        disabled={selectedDomains.size === 0}
                        className="continue-button"
                    >
                        Continue
                    </button>
                </div>
            </div>
        </OnboardingLayout>
    );
};
