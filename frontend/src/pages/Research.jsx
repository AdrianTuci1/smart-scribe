import React from 'react';
import './Research.css';

const Research = () => {
    const researchItems = [
        {
            id: 1,
            date: "October 2024",
            title: "Advancements in Context-Aware Speech Recognition",
            description: "Our latest model improves accuracy in noisy environments by 40% using a novel attention mechanism that isolates speaker voice profiles.",
            link: "Read Paper"
        },
        {
            id: 2,
            date: "August 2024",
            title: "Real-time Sentiment Analysis in Live Transcriptions",
            description: "Implementing lightweight NLP models on-device to detect emotional tone during live speech without compromising latency.",
            link: "View Case Study"
        },
        {
            id: 3,
            date: "May 2024",
            title: "Semantic Understanding of Technical Jargon",
            description: "How Smartscribe learns and adapts to industry-specific terminology through few-shot learning techniques.",
            link: "Learn More"
        }
    ];

    return (
        <main className="research-section">
            <div className="research-container">
                <div className="research-header">
                    <h1 className="research-title">Research & Engineering</h1>
                    <p className="research-subtitle">
                        Pushing the boundaries of what's possible with voice AI. We publish our findings to contribute to the open scientific community.
                    </p>
                </div>

                <div className="research-list">
                    {researchItems.map((item, index) => (
                        <div
                            key={item.id}
                            className={`research-item ${index % 2 !== 0 ? 'reverse' : ''}`}
                        >
                            <div className="research-content">
                                <span className="research-date">{item.date}</span>
                                <h2 className="research-item-title">{item.title}</h2>
                                <p className="research-item-desc">{item.description}</p>
                                <a href="#" className="research-link">
                                    {item.link || "Read More"} <span>→</span>
                                </a>
                            </div>
                            <div className="research-visual">
                                <span>Visual Placeholder {index + 1}</span>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </main>
    );
};

export default Research;
