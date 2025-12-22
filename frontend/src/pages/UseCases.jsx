import React from 'react';
import './UseCases.css';
import DevelopersCase from '../components/cases/DevelopersCase';
import CreatorsCase from '../components/cases/CreatorsCase';
import CustomerSupportCase from '../components/cases/CustomerSupportCase';
import SalesCase from '../components/cases/SalesCase';

const UseCases = () => {
    const cases = [
        {
            id: 1,
            title: "For Developers",
            description: "Document your code reviews and technical discussions effortlessly. Capture standup meetings, architecture decisions, and debugging sessions. Transform verbal explanations into clear technical documentation and searchable knowledge base articles.",
            tags: ["Code Reviews", "Technical Docs", "Standups"]
        },
        {
            id: 2,
            title: "For Creators",
            description: "Turn your podcasts and videos into SEO-friendly blog posts and social media snippets. Repurpose your best spoken content 10x faster and reach a wider audience with text. Generate captions and show notes automatically.",
            tags: ["Podcasts", "YouTube", "Social Media"]
        },
        {
            id: 3,
            title: "For Customer Support",
            description: "Automatically transcribe customer calls and support sessions. Create accurate records of customer issues and resolutions. Build a searchable knowledge base from real conversations to improve response times and training.",
            tags: ["Call Logs", "Issue Tracking", "Knowledge Base"]
        },
        {
            id: 4,
            title: "For Sales",
            description: "Never miss important details from client calls and discovery meetings. Automatically capture requirements, objections, and commitments. Focus on building relationships while Smartscribe handles the note-taking and follow-up items.",
            tags: ["Client Calls", "Discovery", "Follow-ups"]
        }
    ];

    return (
        <main className="usecases-section">
            <div className="usecases-container">
                <div className="usecases-header">
                    <h1 className="usecases-title">Built for everyone</h1>
                    <p className="usecases-subtitle">
                        Whether you're studying, working, or creating, Smartscribe adapts to your workflow.
                    </p>
                </div>

                <div className="usecases-list">
                    {cases.map((useCase, index) => (
                        <div
                            key={useCase.id}
                            className={`usecase-row ${index % 2 !== 0 ? 'reverse' : ''}`}
                        >
                            <div className="usecase-text-col">
                                <h2 className="usecase-row-title">{useCase.title}</h2>
                                <p className="usecase-row-desc">{useCase.description}</p>
                                <div className="usecase-tags">
                                    {useCase.tags.map(tag => (
                                        <span key={tag} className="usecase-tag">{tag}</span>
                                    ))}
                                </div>
                            </div>
                            <div className="usecase-visual-col">
                                <div className="usecase-visual-placeholder">
                                    {index === 0 && <DevelopersCase />}
                                    {index === 1 && <CreatorsCase />}
                                    {index === 2 && <CustomerSupportCase />}
                                    {index === 3 && <SalesCase />}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </main>
    );
};

export default UseCases;
