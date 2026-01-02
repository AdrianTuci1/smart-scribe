import React, { useState } from 'react';
import './Pricing.css';
import { useAuth } from '../contexts/AuthContext';
import AuthModal from '../components/AuthModal';
import { subscriptionService } from '../services/api';

const Pricing = () => {
    const { isAuthenticated, isLoading: authLoading } = useAuth();
    const [isYearly, setIsYearly] = useState(true);
    const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
    const [checkoutLoading, setCheckoutLoading] = useState(false);

    const handleGetStarted = async (plan) => {
        if (plan === 'free') {
            // Usually redirect to app or download
            // For now, let's open the auth modal if not logged in, or redirect to home/app if logged in
            if (!isAuthenticated) {
                setIsAuthModalOpen(true);
            } else {
                // Redirect to app or show "You are on Free plan"
                // window.location.href = 'https://app.smartscribe.ai'; 
                // For demo purposes on landing page:
                alert("You are on the Free plan! Download the app to get started.");
            }
            return;
        }

        // Pro Plan logic
        if (!isAuthenticated) {
            setIsAuthModalOpen(true);
            return;
        }

        // Authenticated -> Go to Checkout
        setCheckoutLoading(true);
        try {
            const interval = isYearly ? 'yearly' : 'monthly';
            const { url } = await subscriptionService.createCheckoutSession(interval);
            if (url) {
                window.location.href = url;
            }
        } catch (error) {
            console.error('Checkout failed', error);
            alert('Failed to start checkout. Please try again.');
        } finally {
            setCheckoutLoading(false);
        }
    };

    return (
        <main className="pricing-section">
            <AuthModal isOpen={isAuthModalOpen} onClose={() => setIsAuthModalOpen(false)} />

            <div className="pricing-container">
                <div className="pricing-header">
                    <h1 className="pricing-title">Simple, transparent pricing</h1>
                    <p className="pricing-subtitle">Start for free, upgrade for power.</p>

                    <div className="pricing-toggle-container">
                        <span className={`toggle-label ${!isYearly ? 'active' : ''}`}>Monthly</span>
                        <button
                            className={`pricing-toggle-switch ${isYearly ? 'yearly' : ''}`}
                            onClick={() => setIsYearly(!isYearly)}
                            aria-label="Toggle billing interval"
                        >
                            <span className="toggle-thumb" />
                        </button>
                        <span className={`toggle-label ${isYearly ? 'active' : ''}`}>
                            Yearly <span className="save-badge">Save $20</span>
                        </span>
                    </div>
                </div>

                <div className="pricing-grid">
                    {/* Free Tier */}
                    <div className="pricing-card">
                        <h3 className="pricing-plan-name">Free</h3>
                        <div className="pricing-price">
                            <span className="pricing-price-amount">$0</span>
                            <span className="pricing-price-period">/forever</span>
                        </div>
                        <p className="pricing-card-desc">
                            Perfect for casual users and hobbyists.
                        </p>

                        <ul className="pricing-features">
                            <li className="pricing-feature-item">
                                <CheckIcon /> 20000 words/month
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon /> Advanced transcription accuracy
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon /> Desktop & Mobile access
                            </li>
                        </ul>

                        <button
                            className="pricing-cta secondary"
                            onClick={() => handleGetStarted('free')}
                        >
                            Get Started
                        </button>
                    </div>

                    {/* Pro Tier */}
                    <div className="pricing-card highlighted">
                        <div className="popular-badge">Most Popular</div>
                        <h3 className="pricing-plan-name">Pro</h3>
                        <div className="pricing-price">
                            <span className="pricing-price-amount">${isYearly ? '100' : '10'}</span>
                            <span className="pricing-price-period">/{isYearly ? 'year' : 'month'}</span>
                        </div>
                        <p className="pricing-card-desc">
                            For professionals who need accurate, reliable transcriptions daily.
                        </p>

                        <ul className="pricing-features">
                            <li className="pricing-feature-item">
                                <CheckIcon color="#ffffff" /> Unlimited transcription
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon color="#ffffff" /> Advanced AI correction
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon color="#ffffff" /> Desktop & Mobile access
                            </li>
                        </ul>

                        <button
                            className="pricing-cta"
                            onClick={() => handleGetStarted('pro')}
                            disabled={checkoutLoading || authLoading}
                        >
                            {checkoutLoading ? 'Redirecting...' : 'Get Started'}
                        </button>
                    </div>
                </div>

                <p className="pricing-note">
                    All plans include a 14-day money-back guarantee. No credit card required for Free plan.
                </p>
            </div>
        </main>
    );
};

const CheckIcon = ({ color = "#3b82f6" }) => (
    <svg
        className="pricing-feature-icon"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{ color: color }}
    >
        <path d="M20 6L9 17L4 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
);

export default Pricing;
