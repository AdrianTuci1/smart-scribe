import React, { useState } from 'react';
import { LoginStep } from './LoginStep';
import { DomainSelectionStep } from './DomainSelectionStep';
import { PlaceholderStep } from './PlaceholderStep';
import { QuestionStep } from './QuestionStep';
import { DataControlStep } from './DataControlStep';
import { PermissionsStep } from './PermissionsStep';
import { MicTestStep } from './MicTestStep';
import { ShortcutTestStep } from './ShortcutTestStep';

interface OnboardingViewProps {
    onComplete: () => void;
}

export const OnboardingView: React.FC<OnboardingViewProps> = ({ onComplete }) => {
    const [currentStep, setCurrentStep] = useState(0);
    const [source, setSource] = useState<Set<string>>(new Set());
    const [role, setRole] = useState<Set<string>>(new Set());
    const [usage, setUsage] = useState<Set<string>>(new Set());
    const [permissionsSkipped, setPermissionsSkipped] = useState(false);

    // Total steps configuration
    // 0: Login
    // 1: Source (Where did you hear)
    // 2: Role (What do you do)
    // 3: Usage (Where do you spend time)
    // 4: Data Control (Privacy/Share)
    // 5: Permissions (Accessibility & Mic Request)
    // 6: Mic Test (Visualizer)
    // 7: Shortcut Test (Fn key)
    // 8: Success/Learn
    const TOTAL_STEPS = 8;

    const nextStep = () => setCurrentStep(prev => prev + 1);

    // Helper to update selection sets
    const handleSelection = (setFn: React.Dispatch<React.SetStateAction<Set<string>>>, multi: boolean) => (id: string) => {
        setFn(prev => {
            const next = new Set(multi ? prev : []);
            if (next.has(id)) {
                if (multi) next.delete(id);
            } else {
                next.add(id);
            }
            return next;
        });
    };

    const sourceOptions = [
        { id: 'social', label: 'Social media' }, { id: 'youtube', label: 'Youtube' },
        { id: 'newsletter', label: 'Newsletter' }, { id: 'ai_chat', label: 'AI chat' },
        { id: 'search', label: 'Search engine' }, { id: 'event', label: 'Event' },
        { id: 'friend', label: 'Friend' }, { id: 'colleague', label: 'Colleague' },
        { id: 'podcast', label: 'Podcast' }, { id: 'article', label: 'Article' },
        { id: 'product_hunt', label: 'Product Hunt' }, { id: 'techcrunch', label: 'TechCrunch' },
        { id: 'diary', label: 'Diary of a CEO' }, { id: 'ruben', label: 'Ruben Hassid' },
        { id: 'radio', label: 'Radio' }, { id: 'computerworld', label: 'Computerworld' },
        { id: 'opal', label: 'Opal' }, { id: 'billboard', label: 'Billboard' }, { id: 'other', label: 'Other' }
    ];

    const roleOptions = [
        { id: 'founder', label: 'Founder/CEO' }, { id: 'consultant', label: 'Consultant' },
        { id: 'operations', label: 'Operations' }, { id: 'developer', label: 'Developer' },
        { id: 'product', label: 'Product' }, { id: 'data', label: 'Data Analysis' },
        { id: 'sales', label: 'Sales' }, { id: 'marketing', label: 'Marketing' },
        { id: 'support', label: 'Customer Support' }, { id: 'recruiting', label: 'Recruiting' },
        { id: 'creator', label: 'Creator' }, { id: 'writer', label: 'Writer' },
        { id: 'educator', label: 'Educator' }, { id: 'student', label: 'Student' },
        { id: 'legal', label: 'Legal' }, { id: 'healthcare', label: 'Healthcare' }, { id: 'other', label: 'Other' }
    ];

    const usageOptions = [
        { id: 'chatting', label: 'Chatting with AI' }, { id: 'messages', label: 'Sending messages' },
        { id: 'coding', label: 'Coding with AI' }, { id: 'emails', label: 'Drafting emails' },
        { id: 'docs', label: 'Writing documents' }, { id: 'notes', label: 'Taking notes' },
        { id: 'posts', label: 'Writing posts or comments' }, { id: 'other', label: 'Something else' }
    ];

    switch (currentStep) {
        case 0:
            return <LoginStep key="login" onNext={nextStep} />;
        case 1:
            return (
                <QuestionStep
                    key="source"
                    title="Welcome, User!" // TODO: Get name from auth
                    subtitle="Where did you hear about us?"
                    options={sourceOptions}
                    selected={source}
                    onSelect={handleSelection(setSource, true)}
                    multiSelect={true}
                    onNext={nextStep}
                    onSkip={nextStep} // Allow skip
                    currentStep={1}
                    totalSteps={TOTAL_STEPS}
                // visualImage / placeholder handled by component defaults
                />
            );
        case 2:
            return (
                <QuestionStep
                    key="role"
                    title="Tell us about yourself"
                    subtitle="What do you do for work?"
                    options={roleOptions}
                    selected={role}
                    onSelect={handleSelection(setRole, true)}
                    multiSelect={true}
                    onNext={nextStep}
                    onSkip={nextStep}
                    currentStep={2}
                    totalSteps={TOTAL_STEPS}
                />
            );
        case 3:
            return (
                <QuestionStep
                    key="usage"
                    title="Where do you spend time typing?"
                    subtitle="This helps us personalize Flow where you work. Select all that apply."
                    options={usageOptions}
                    selected={usage}
                    onSelect={handleSelection(setUsage, true)}
                    multiSelect={true}
                    onNext={nextStep}
                    onSkip={nextStep}
                    currentStep={3}
                    totalSteps={TOTAL_STEPS}
                />
            );
        case 4:
            return <DataControlStep key="data" onNext={nextStep} />;
        case 5:
            return <PermissionsStep key="perms" onNext={nextStep} />;
        case 6:
            return <MicTestStep key="mictest" onNext={nextStep} />;
        case 7:
            return <ShortcutTestStep key="shortcut" onNext={onComplete} />; // End of flow for now

        default:
            return null;
    }
};
