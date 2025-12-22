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
                    {/* Waveform - placeholder for orb */}
                    <div className="customer-support-case__waveform">
                        {[
                            { height: 6, type: 'gray-dark' },
                            { height: 10, type: 'gray-dark' },
                            { height: 8, type: 'gray-dark' },
                            { height: 14, type: 'orange' },
                            { height: 12, type: 'orange' },
                            { height: 16, type: 'orange' },
                            { height: 20, type: 'gray-dark' },
                            { height: 18, type: 'gray-dark' },
                            { height: 24, type: 'gray-dark' },
                            { height: 22, type: 'gray-dark' },
                            { height: 26, type: 'gray-dark' },
                            { height: 22, type: 'gray-dark' },
                            { height: 18, type: 'gray-dark' },
                            { height: 16, type: 'gray-dark' },
                            { height: 14, type: 'gray-dark' },
                            { height: 12, type: 'gray-dark' },
                            { height: 10, type: 'gray-dark' },
                            { height: 8, type: 'gray-dark' },
                            { height: 6, type: 'gray-dark' },
                            { height: 4, type: 'gray-light' },
                            { height: 4, type: 'gray-light' },
                            { height: 4, type: 'gray-light' },
                            { height: 4, type: 'gray-light' },
                            { height: 4, type: 'gray-light' },
                        ].map((bar, i) => (
                            <div
                                key={i}
                                className={`customer-support-case__waveform-bar customer-support-case__waveform-bar--${bar.type}`}
                                style={{ height: `${bar.height}px` }}
                            ></div>
                        ))}
                    </div>

                    {/* Transcription text with refined typography */}
                    <div>
                        <p className="customer-support-case__transcription-text">
                            <span className="customer-support-case__filler-word">umm</span>{' '}
                            <span className="customer-support-case__name-badge">Caty</span>{' '}
                            <span className="customer-support-case__text-medium">
                                i'll meet you at <span className="customer-support-case__strikethrough">5pm, no</span> <span className="customer-support-case__corrected-text">6pm</span>
                            </span>
                        </p>
                    </div>
                </div>

                {/* Response bubble with gradient */}
                <div className="customer-support-case__response-bubble">
                    <p className="customer-support-case__response-text">
                        Hey Caty, I'll meet you at 6pm.
                    </p>
                </div>
            </div>
        </div>
    );
};

export default CustomerSupportCase;
