import React from 'react';
import './DevelopersCase.css';

const DevelopersCase = () => {
    return (
        <div className="developers-case">
            {/* Subtle overlay for better contrast */}
            <div className="developers-case__overlay"></div>

            {/* Content container */}
            <div className="developers-case__content-container">
                {/* Chat bubble with glassmorphism */}
                <div className="developers-case__chat-bubble">
                    {/* Message content */}
                    <div className="developers-case__message">
                        <p className="developers-case__message-text">
                            Yo Alex, quick update on the CI/CD pipeline. The K8s cluster is scaling as expected now. v2.1.0 should be live on staging within the hour.
                        </p>
                    </div>

                    {/* Divider with gradient */}
                    <div className="developers-case__divider"></div>

                    {/* Toolbar */}
                    <div className="developers-case__toolbar">
                        <div className="developers-case__toolbar-left">
                            {/* Bold */}
                            <button className="developers-case__toolbar-button developers-case__toolbar-button--bold">
                                <span>B</span>
                            </button>

                            {/* Italic */}
                            <button className="developers-case__toolbar-button developers-case__toolbar-button--italic">
                                <span>I</span>
                            </button>

                            {/* Strikethrough */}
                            <button className="developers-case__toolbar-button developers-case__toolbar-button--strikethrough">
                                <span>S</span>
                            </button>

                            {/* Link */}
                            <button className="developers-case__toolbar-button">
                                <svg className="developers-case__toolbar-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                                </svg>
                            </button>

                            {/* Bullet list */}
                            <button className="developers-case__toolbar-button">
                                <svg className="developers-case__toolbar-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                                    <circle cx="6" cy="6" r="1.5" fill="currentColor" />
                                    <circle cx="6" cy="12" r="1.5" fill="currentColor" />
                                    <circle cx="6" cy="18" r="1.5" fill="currentColor" />
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M11 6h10M11 12h10M11 18h10" />
                                </svg>
                            </button>

                            {/* Numbered list */}
                            <button className="developers-case__toolbar-button">
                                <svg className="developers-case__toolbar-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h10M4 18h16" />
                                </svg>
                            </button>

                            {/* Code */}
                            <button className="developers-case__toolbar-button developers-case__toolbar-button--code">
                                <span>&lt;/&gt;</span>
                            </button>
                        </div>

                        {/* Send button with gradient */}
                        <button className="developers-case__send-button">
                            <svg className="developers-case__send-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2.5}>
                                <path strokeLinecap="round" strokeLinejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default DevelopersCase;
