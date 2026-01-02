import React, { useState } from 'react';
import { CheckCircle, FileText, ChevronRight, Loader2 } from 'lucide-react';
import { SettingsTabProps } from './types';
import { apiService } from '../../services/api';

const plans = [
    { id: 'free', name: 'Free', price: '$0', features: ['Advanced transcription', '2000 words/month'] },
    { id: 'pro', name: 'Pro', price: '$9.99', features: ['Advanced transcription', 'Unlimited Words'] },
];

export const PlansBillingSettings: React.FC<SettingsTabProps> = () => {
    const [selectedPlan, setSelectedPlan] = useState<string>('free');
    const [isLoading, setIsLoading] = useState<string | null>(null);

    const handleUpgrade = async (planId: string) => {
        if (planId === 'free') return;

        try {
            setIsLoading(planId);
            // Default to monthly for the Pro button in this simplified UI
            const { url } = await apiService.createCheckoutSession('monthly');
            if (url) {
                // Open in default browser ideally, or verify behavior
                window.open(url, '_blank');
            }
        } catch (error) {
            console.error('Failed to start checkout:', error);
            // TODO: Show toast error
        } finally {
            setIsLoading(null);
        }
    };

    const handleManageBilling = async () => {
        try {
            setIsLoading('portal');
            const { url } = await apiService.createPortalSession();
            if (url) {
                window.open(url, '_blank');
            }
        } catch (error) {
            console.error('Failed to open billing portal:', error);
        } finally {
            setIsLoading(null);
        }
    };

    return (
        <>
            <div className="settings-section">
                <h3 className="settings-section-title">Available Plans</h3>
                <div className="plans-grid">
                    {plans.map(plan => (
                        <div key={plan.id} className={`plan-card ${selectedPlan === plan.id ? 'selected' : ''}`}>
                            <div className="plan-header">
                                <div className="plan-name">{plan.name}</div>
                                <div className="plan-price">{plan.price}/mo</div>
                            </div>
                            <div className="plan-features">
                                {plan.features.map(feature => (
                                    <div key={feature} className="plan-feature">
                                        <CheckCircle size={16} />
                                        <span>{feature}</span>
                                    </div>
                                ))}
                            </div>
                            {plan.id !== 'free' && selectedPlan !== plan.id && (
                                <button
                                    className="plan-action-button"
                                    onClick={() => handleUpgrade(plan.id)}
                                    disabled={!!isLoading}
                                >
                                    {isLoading === plan.id ? (
                                        <Loader2 size={16} className="animate-spin" />
                                    ) : (
                                        'Upgrade'
                                    )}
                                </button>
                            )}
                            {selectedPlan === plan.id && (
                                <div className="current-plan-badge">Current Plan</div>
                            )}
                        </div>
                    ))}
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Billing History</h3>
                <div className="settings-card">
                    <button
                        className="settings-action-button"
                        onClick={handleManageBilling}
                        disabled={!!isLoading}
                    >
                        {isLoading === 'portal' ? <Loader2 size={18} className="animate-spin" /> : <FileText size={18} />}
                        <span>View Billing History & Manage Subscription</span>
                        <ChevronRight size={18} style={{ marginLeft: 'auto' }} />
                    </button>
                </div>
            </div>
        </>
    );
};

