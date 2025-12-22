import React from 'react';
import './CustomerSupportCase.css';

const CustomerSupportCase = () => {
    return (
        <div className="customer-support-case">
            {/* Subtle overlay */}
            <div className="customer-support-case__overlay"></div>

            <div className="customer-support-case__content">
                {/* Transcription bubble with refined design */}
                <div className="customer-support-case__transcription-bubble">
                    {/* Centered orb from TryButton style, scoped */}
                    <div className="customer-support-case__orb"></div>

                    {/* Transcription text with refined typography */}
                    <div className="customer-support-case__transcription-content">
                        <p className="customer-support-case__transcription-text">
                            <span className="customer-support-case__filler-word">umm</span>{' '}
                            <span className="customer-support-case__name-badge">Sarah</span>{' '}
                            <span className="customer-support-case__text-medium">
                                i'll meet you at <span className="customer-support-case__strikethrough">5pm, no</span> <span className="customer-support-case__corrected-text">6pm</span>
                            </span>
                        </p>
                    </div>
                </div>

                {/* Response bubble with gradient */}
                <div className="customer-support-case__response-bubble">
                    <p className="customer-support-case__response-text">
                        Hey Sarah, I'll meet you at 6pm.
                    </p>
                </div>
            </div>
        </div>
    );
};

export default CustomerSupportCase;
