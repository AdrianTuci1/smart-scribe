import React from 'react';
import './CreatorsCase.css';

const CreatorsCase = () => {
    return (
        <div className="creators-case">
            {/* Background Image */}
            <div className="creators-case__background">
                <div className="creators-case__background-image"></div>
            </div>

            {/* Main container */}
            <div className="creators-case__main-container">
                {/* Left sidebar - smaller and refined */}
                <div className="creators-case__sidebar">
                    {/* App icons - smaller */}
                    <div className="creators-case__icon creators-case__icon--white">
                        <div className="creators-case__icon-shape"></div>
                    </div>

                    {/* Waveform icon - placeholder for orb */}
                    <div className="creators-case__icon creators-case__icon--white-transparent">
                        <div className="creators-case__waveform">
                            {[3, 5, 2, 6, 4, 7, 5].map((height, i) => (
                                <div
                                    key={i}
                                    className="creators-case__waveform-bar"
                                    style={{ height: `${height * 2}px` }}
                                ></div>
                            ))}
                        </div>
                    </div>

                    <div className="creators-case__icon creators-case__icon--green">
                        <div className="creators-case__icon-circle"></div>
                    </div>

                    <div className="creators-case__icon creators-case__icon--blue">
                        <div className="creators-case__icon-text">///</div>
                    </div>
                </div>

                {/* Main content area */}
                <div className="creators-case__content">
                    {/* Waveform header - placeholder for orb */}
                    <div className="creators-case__header-waveform">
                        {[4, 8, 6, 12, 8, 15, 10, 18, 12, 20, 14, 18, 10, 15, 8, 12, 6, 8, 4].map((height, i) => (
                            <div
                                key={i}
                                className="creators-case__header-waveform-bar"
                                style={{ height: `${height}px` }}
                            ></div>
                        ))}
                    </div>

                    {/* Email content - positioned to show partial view */}
                    <div className="creators-case__email-container">
                        <div className="creators-case__email-card">
                            <p className="creators-case__email-greeting">
                                <span className="creators-case__email-greeting-name">Hi Daveed,</span>
                            </p>

                            <p className="creators-case__email-text">
                                Thanks for getting in touch. We've got to fix this for you!
                            </p>

                            <p className="creators-case__email-text creators-case__email-text--last">
                                I'll come back later today with a solution.
                            </p>

                            <div className="creators-case__email-signature">
                                <p className="creators-case__email-signature-text">
                                    <span className="creators-case__email-signature-name">Best,</span><br />
                                    <span className="creators-case__email-signature-name">Samm</span>
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CreatorsCase;
