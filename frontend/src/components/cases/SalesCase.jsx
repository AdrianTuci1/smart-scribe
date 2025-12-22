import React from 'react';
import './SalesCase.css';

const SalesCase = () => {
    return (
        <div className="sales-case">
            {/* Background Image - Blurred */}
            <div className="sales-case__background">
                <div className="sales-case__background-image"></div>
            </div>

            {/* Main Desktop Mockup - Partial View with White Border */}
            <div className="sales-case__desktop-container">
                <div className="sales-case__inner-container">
                    <div className="sales-case__content">
                        {/* Email header with refined design */}
                        <div className="sales-case__header">
                            <div className="sales-case__recipient-row">
                                <span className="sales-case__label">To</span>
                                <div className="sales-case__recipient-info">
                                    <div className="sales-case__avatar">
                                        Q
                                    </div>
                                    <span className="sales-case__recipient-name">Quackenbush Miller</span>
                                </div>
                            </div>

                            <div className="sales-case__divider"></div>

                            <div className="sales-case__subject-section">
                                <span className="sales-case__label">Subject</span>
                                <p className="sales-case__subject-text">
                                    Clarification Request for Concepts in Quantum Neurophilosophy – PHIL-4892
                                </p>
                            </div>

                            <div className="sales-case__divider--thin"></div>
                        </div>

                        {/* Email body with improved typography */}
                        <div className="sales-case__body">
                            <div className="sales-case__body-content">
                                <p className="sales-case__paragraph">Dear Professor Quackenbush,</p>

                                <p className="sales-case__paragraph">
                                    I hope you're doing well. I'm writing to seek clarification on some of the concepts discussed in your lecture for Quantum Neurophilosophy: The Entangled Mind and the Logic of Non-Being (PHIL-4892).
                                </p>

                                <p className="sales-case__paragraph">
                                    While reviewing the material, I found a few terms and frameworks quite complex. I would deeply appreciate any guidance or additional resources you could provide. Specifically:
                                </p>

                                <ul className="sales-case__list">
                                    <li className="sales-case__list-item">
                                        <span className="sales-case__bullet sales-case__bullet--purple">•</span>
                                        <span className="sales-case__list-item-text">
                                            <span className="sales-case__list-item-label">"Onto-epistemic feedback loops":</span> I'm struggling to understand how these interact with recent consciousness models.
                                        </span>
                                    </li>
                                    <li className="sales-case__list-item">
                                        <span className="sales-case__bullet sales-case__bullet--blue">•</span>
                                        <span className="sales-case__list-item-text">
                                            <span className="sales-case__list-item-label">The Schrödinger-Derrida Paradox:</span> I'm unclear on its implications in the context of post-structural cognition.
                                        </span>
                                    </li>
                                    <li className="sales-case__list-item">
                                        <span className="sales-case__bullet sales-case__bullet--orange">•</span>
                                        <span className="sales-case__list-item-text">
                                            Your mention of <span className="sales-case__list-item-label">"metaphysical defragmentation"</span> as applied to the self-aware algorithm — could you elaborate or point me to further reading?
                                        </span>
                                    </li>
                                </ul>
                            </div>
                        </div>

                        {/* Toolbar with refined buttons */}
                        <div className="sales-case__toolbar">
                            <button className="sales-case__toolbar-button sales-case__toolbar-button--bold">
                                <span>B</span>
                            </button>

                            <button className="sales-case__toolbar-button sales-case__toolbar-button--italic">
                                <span>I</span>
                            </button>

                            <button className="sales-case__toolbar-button">
                                <svg className="sales-case__toolbar-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                                    <circle cx="6" cy="6" r="1.5" fill="currentColor" />
                                    <circle cx="6" cy="12" r="1.5" fill="currentColor" />
                                    <circle cx="6" cy="18" r="1.5" fill="currentColor" />
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M11 6h10M11 12h10M11 18h10" />
                                </svg>
                            </button>

                            <button className="sales-case__toolbar-button">
                                <svg className="sales-case__toolbar-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h10M4 18h16" />
                                </svg>
                            </button>

                            <button className="sales-case__toolbar-button">
                                <svg className="sales-case__toolbar-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                </svg>
                            </button>

                            {/* Waveform button - placeholder for orb */}
                            <button className="sales-case__waveform-button">
                                {[4, 8, 6, 11, 9, 13, 10, 14, 11, 13, 9, 11, 6, 8, 4].map((height, i) => (
                                    <div
                                        key={i}
                                        className="sales-case__waveform-bar"
                                        style={{ height: `${height}px` }}
                                    ></div>
                                ))}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default SalesCase;
