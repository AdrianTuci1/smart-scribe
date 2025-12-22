import React from 'react';
import { Link } from 'react-router-dom';
import './Research.css';

const Research = () => {
    const researchItems = [
        {
            id: 1,
            date: "December 2024",
            title: "The Invisible Interface: How Smartscribe Rethinks Voice AI",
            description: "We are at the beginning of a new interface era. But instead of seeing radical new forms, we see a strange recursion: AI tools wrapped in old patterns. Discover how Smartscribe takes a different path.",
            link: "/research/invisible-interface",
            linkText: "Read Article"
        },
        {
            id: 2,
            date: "November 2024",
            title: "Building Trust Through Voice: How Smartscribe Creates Lasting Habits",
            description: "Our approach to voice interfaces centers on creating sticky habits that fit seamlessly into people's lives. Learn how we're building trust through workflows that matter.",
            link: "/research/voice-habits",
            linkText: "Read Article"
        },
        {
            id: 3,
            date: "October 2024",
            title: "Engineering Excellence: The Technical Challenges Behind Smartscribe",
            description: "Building voice AI that people trust requires solving hard problems in ML, systems engineering, and UX design. Explore the technical challenges we're tackling to make voice feel effortless.",
            link: "/research/technical-challenges",
            linkText: "Read Article"
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
                                {item.link ? (
                                    <Link to={item.link} className="research-link">
                                        {item.linkText || "Read More"} <span>→</span>
                                    </Link>
                                ) : (
                                    <a href="#" className="research-link">
                                        {item.linkText || "Read More"} <span>→</span>
                                    </a>
                                )}
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
