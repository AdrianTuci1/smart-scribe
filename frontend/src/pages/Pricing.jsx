import React from 'react';
import './Pricing.css';

const Pricing = () => {
    return (
        <main className="pricing-section">
            <div className="pricing-container">
                <div className="pricing-header">
                    <h1 className="pricing-title">Simple, transparent pricing</h1>
                    <p className="pricing-subtitle">
                        Choose the plan that fits your needs.
                        <br />No hidden fees, cancel anytime.
                    </p>
                </div>

                <div className="pricing-grid">
                    {/* Pro Tier */}
                    <div className="pricing-card highlighted">
                        <h3 className="pricing-plan-name">Pro</h3>
                        <div className="pricing-price">
                            <span className="pricing-price-amount">$19</span>
                            <span className="pricing-price-period">/month</span>
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
                                <CheckIcon color="#ffffff" /> Custom vocabulary
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon color="#ffffff" /> Export to all formats
                            </li>
                        </ul>

                        <button className="pricing-cta">Start Free Trial</button>
                    </div>

                    {/* Enterprise Tier */}
                    <div className="pricing-card">
                        <h3 className="pricing-plan-name">Enterprise</h3>
                        <div className="pricing-price">
                            <span className="pricing-price-amount">Custom</span>
                        </div>
                        <p className="pricing-card-desc">
                            Scalable solutions for teams and organizations with added security.
                        </p>

                        <ul className="pricing-features">
                            <li className="pricing-feature-item">
                                <CheckIcon /> Dedicated support
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon /> SSO & Admin controls
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon /> API access
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon /> Custom retention
                            </li>
                            <li className="pricing-feature-item">
                                <CheckIcon /> On-premise deployment
                            </li>
                        </ul>

                        <button className="pricing-cta secondary">Contact Sales</button>
                    </div>
                </div>
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
