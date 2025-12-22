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
            description: "Streamline your development workflow by capturing technical updates, CI/CD pipeline status, and infrastructure decisions. Transform dev standups and architecture discussions into actionable documentation and clear team updates.",
            tags: ["CI/CD Status", "Infra Decisions", "Staging Updates"]
        },
        {
            id: 2,
            title: "For Creators",
            description: "Manage your creative projects and support requests with ease. Capture client feedback on asset rendering and technical issues seamlessly. Perfect for busy creators who need to turn verbal requests into trackable dashboard actions.",
            tags: ["Asset Support", "Rendering Fixes", "Creator Dashboard"]
        },
        {
            id: 3,
            title: "For Customer Support",
            description: "Automatically transcribe customer calls and support sessions. Create accurate records of customer issues and resolutions. Build a searchable knowledge base from real conversations to improve response times and training.",
            tags: ["Call Logs", "Issue Tracking", "Knowledge Base"]
        },
        {
            id: 4,
            title: "For Education & Research",
            description: "Capture complex academic lectures and research inquiries with precision. From Computational Bioethics to Neural-synthetic autonomy, Smartscribe helps students and researchers document every detail for deeper study and follow-up.",
            tags: ["Lecture Notes", "Academic Inquiry", "Research Details"]
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
