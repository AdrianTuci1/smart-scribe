import React, { useState } from 'react';
import { LoginStep } from './LoginStep';
import { DomainSelectionStep } from './DomainSelectionStep';
import { PlaceholderStep } from './PlaceholderStep';
import { QuestionStep } from './QuestionStep';
import { DataControlStep } from './DataControlStep';
import { PermissionsStep } from './PermissionsStep';
import { MicTestStep } from './MicTestStep';
import { ShortcutTestStep } from './ShortcutTestStep';
import { LanguageSelectionStep } from './LanguageSelectionStep';
import { InteractiveLearnStep } from './InteractiveLearnStep';
import { FreeTrialStep } from './FreeTrialStep';
import { ReferralStep } from './ReferralStep';
import { configService } from '../../services/api';

interface OnboardingViewProps {
    onComplete: () => void;
}

export const OnboardingView: React.FC<OnboardingViewProps> = ({ onComplete }) => {
    const [currentStep, setCurrentStep] = useState(0);
    const [source, setSource] = useState<Set<string>>(new Set());
    const [role, setRole] = useState<Set<string>>(new Set());
    const [usage, setUsage] = useState<Set<string>>(new Set());
    const [permissionsSkipped, setPermissionsSkipped] = useState(false);


    // 0: Login
    // 1: Source (Where did you hear)
    // 2: Role (What do you do)
    // 3: Usage (Where do you spend time)
    // 4: Language Selection
    // 5: Data Control (Privacy/Share)
    // 6: Permissions (Accessibility & Mic Request)
    // 7: Mic Test (Visualizer)
    // 8: Shortcut Test (Fn key)
    // 9: Interactive Learn (Simulated Tabs)
    // 10: Free Trial
    // 11: Referral
    // 12: Success/Learn
    const TOTAL_STEPS = 12;

    const handleComplete = async () => {
        try {
            await configService.updateOnboarding({
                source: Array.from(source),
                role: Array.from(role),
                usage: Array.from(usage)
            });
        } catch (error) {
            console.error('Failed to save onboarding data:', error);
            // We initiate completion anyway so we don't block the user
        }
        onComplete();
    };

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
        { id: 'radio', label: 'Radio' }, { id: 'computerworld', label: 'Computerworld' },
        { id: 'other', label: 'Other' }
    ];

    const roleOptions = [
        { id: 'developer', label: 'Developer' },
        { id: 'product', label: 'Product' }, { id: 'data', label: 'Data Analysis' },
        { id: 'sales', label: 'Sales' }, { id: 'marketing', label: 'Marketing' },
        { id: 'support', label: 'Customer Support' }, { id: 'recruiting', label: 'Recruiting' },
        { id: 'creator', label: 'Creator' }, { id: 'writer', label: 'Writer' },
        { id: 'educator', label: 'Educator' }, { id: 'student', label: 'Student' },
        { id: 'legal', label: 'Legal' }, { id: 'healthcare', label: 'Healthcare' }, { id: 'other', label: 'Other' }
    ];

    const usageOptions = [
        { id: 'messages', label: 'Sending messages' },
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
                    subtitle="This helps us personalize Smartscribe where you work. Select all that apply."
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
            return (
                <LanguageSelectionStep
                    key="language"
                    onNext={nextStep}
                    onBack={() => setCurrentStep(prev => prev - 1)}
                    currentStep={4}
                    totalSteps={TOTAL_STEPS}
                />
            );
        case 5:
            return <DataControlStep key="data" onNext={nextStep} />;
        case 6:
            return <PermissionsStep key="perms" onNext={nextStep} />;
        case 7:
            return <MicTestStep key="mictest" onNext={nextStep} />;
        case 8:
            return <ShortcutTestStep key="shortcut" onNext={nextStep} />;
        case 9:
            return (
                <InteractiveLearnStep
                    key="learn"
                    onNext={nextStep}
                    onSkip={nextStep} // For now skip goes to complete
                    currentStep={9}
                    totalSteps={TOTAL_STEPS}
                />
            );
        case 10:
            return (
                <FreeTrialStep
                    key="freetrial"
                    onNext={nextStep}
                    onBack={() => setCurrentStep(prev => prev - 1)}
                    currentStep={10}
                    totalSteps={TOTAL_STEPS}
                />
            );
        case 11:
            return (
                <ReferralStep
                    key="referral"
                    onComplete={handleComplete}
                    onBack={() => setCurrentStep(prev => prev - 1)}
                    currentStep={11}
                    totalSteps={TOTAL_STEPS}
                />
            );

        default:
            return null;
    }
};
