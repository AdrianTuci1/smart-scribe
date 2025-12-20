import React from 'react';
import './UseCases.css';

const UseCases = () => {
    const cases = [
        {
            id: 1,
            title: "For Students & Researchers",
            description: "Capture lectures and seminars without missing a beat. Search through hours of audio instantly to find that one specific reference for your paper. Focus on understanding the material instead of frantically taking notes.",
            tags: ["Lecture Notes", "Thesis Research", "Study Groups"]
        },
        {
            id: 2,
            title: "For Meeting Minutes",
            description: "Automate your meeting workflow. Smartscribe identifies different speakers and generates concise summaries with action items. Keeps everyone aligned without the administrative burden.",
            tags: ["Team Syncs", "Client Calls", "Board Meetings"]
        },
        {
            id: 3,
            title: "For Content Creators",
            description: "Turn your podcasts and videos into SEO-friendly blog posts and social media snippets. Repurpose your best spoken content 10x faster and reach a wider audience with text.",
            tags: ["Podcasts", "YouTube", "Social Media"]
        },
        {
            id: 4,
            title: "For Medical Professionals",
            description: "Secure, HIPAA-compliant transcription for patient notes. Dictate your observations naturally and let Smartscribe format them into structured medical records. Focus on care while we handle the documentation.",
            tags: ["Patient Notes", "Consultations", "Medical Records"]
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
                                    <span>Image Placeholder {index + 1}</span>
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
