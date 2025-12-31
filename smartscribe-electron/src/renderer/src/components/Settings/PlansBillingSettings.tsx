import React, { useState } from 'react';
import { CheckCircle, FileText, ChevronRight } from 'lucide-react';
import { SettingsTabProps } from './types';

const plans = [
    { id: 'free', name: 'Free', price: '$0', features: ['Basic transcription', '100 minutes/month'] },
    { id: 'basic', name: 'Basic', price: '$9.99', features: ['Advanced transcription', '500 minutes/month', 'Basic formatting'] },
    { id: 'pro', name: 'Pro', price: '$19.99', features: ['Unlimited transcription', 'Advanced formatting', 'Priority support'] },
    { id: 'enterprise', name: 'Enterprise', price: 'Custom', features: ['Custom features', 'Dedicated support', 'SLA guarantee'] },
];

export const PlansBillingSettings: React.FC<SettingsTabProps> = () => {
    const [selectedPlan, setSelectedPlan] = useState<string>('free');

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
                        </div>
                    ))}
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Billing History</h3>
                <div className="settings-card">
                    <button className="settings-action-button">
                        <FileText size={18} />
                        <span>View Billing History</span>
                        <ChevronRight size={18} style={{ marginLeft: 'auto' }} />
                    </button>
                </div>
            </div>
        </>
    );
};
