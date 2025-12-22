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
                <div className="creators-case__glass-container">
                    {/* Integrated sidebar */}
                    <div className="creators-case__sidebar">
                        <div className="creators-case__icon creators-case__icon--white">
                            <div className="creators-case__icon-shape"></div>
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
                        {/* Centered orb */}
                        <div className="creators-case__orb"></div>

                        {/* Email content */}
                        <div className="creators-case__email-container">
                            <div className="creators-case__email-card">
                                <p className="creators-case__email-greeting">
                                    <span className="creators-case__email-greeting-name">Hey Sarah,</span>
                                </p>

                                <p className="creators-case__email-text">
                                    Good to hear from you. We're looking into the asset rendering issue right away.
                                </p>

                                <p className="creators-case__email-text creators-case__email-text--last">
                                    Expect a fix in your dashboard by this evening.
                                </p>

                                <div className="creators-case__email-signature">
                                    <p className="creators-case__email-signature-text">
                                        <span className="creators-case__email-signature-name">Cheers,</span><br />
                                        <span className="creators-case__email-signature-name">Mark</span>
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CreatorsCase;
