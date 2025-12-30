import React, { useState, useEffect } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { Send, Check } from 'lucide-react';
import './InteractiveLearnStep.css';

interface InteractiveLearnStepProps {
    onNext: () => void;
    onSkip?: () => void;
    currentStep?: number;
    totalSteps?: number;
}

type TabType = 'message' | 'email' | 'note';

export const InteractiveLearnStep: React.FC<InteractiveLearnStepProps> = ({
    onNext,
    onSkip,
    currentStep,
    totalSteps
}) => {
    const [activeTab, setActiveTab] = useState<TabType>('message');

    // Trigger Floating Waveform on mount
    useEffect(() => {
        const electron = (window as any).electron;
        if (electron && electron.ipcRenderer) {
            console.log('Triggering Waveform Opening for Learn Step');
            electron.ipcRenderer.openWaveform();
        }
        // Ideally we might want to close it on unmount, but the flow usually continues to success or main app where it might persist.
        // For now let's leave it open.
    }, []);

    const renderContent = () => {
        switch (activeTab) {
            case 'message':
                return (
                    <>
                        <h1 className="learn-step-title">Press the keyboard shortcut to use Smartscribe</h1>
                        <div className="learn-step-subtitle">
                            Hold down on the <span className="shortcut-key-box">fn</span> key, speak, and let go to insert spoken text.
                        </div>
                    </>
                );
            case 'email':
                return (
                    <>
                        <h1 className="learn-step-title">Draft emails at lightning speed</h1>
                        <div className="learn-step-subtitle">
                            Smartscribe seamlessly integrates with your email client. Just press <span className="shortcut-key-box">fn</span> and start talking to draft.
                        </div>
                    </>
                );
            case 'note':
                return (
                    <>
                        <h1 className="learn-step-title">Smartscribe even works when you whisper</h1>
                        <div className="learn-step-subtitle">
                            Dictate a note close to your mic. Smartscribe will auto-format lists for you.
                        </div>
                    </>
                );
        }
    };

    // Simple Markdown Renderer Helper
    const renderMarkdown = (text: string) => {
        return text.split('\n').map((line, i) => {
            if (line.startsWith('- ') || line.startsWith('* ')) {
                return (
                    <div key={i} className="notion-list-item">
                        <span style={{ fontSize: 6, marginRight: 8 }}>●</span>
                        {line.substring(2)}
                    </div>
                );
            }
            if (line.trim() === '') {
                return <br key={i} />;
            }
            return <div key={i} style={{ marginBottom: 4 }}>{line}</div>;
        });
    };

    // Placeholder state can be managed by checking if content exists.
    // For now we assume empty content to show placeholders as requested.
    const emailContent = ""; // Simulating empty state
    const noteContent = "";  // Simulating empty state

    const renderVisualMock = () => {
        switch (activeTab) {
            case 'message':
                return (
                    <div className="models-card mock-card slack-mock">
                        <div className="slack-header">
                            <img src="https://cdn-icons-png.flaticon.com/512/2111/2111615.png" className="slack-logo-icon" alt="Slack" />
                            <span className="slack-app-name">Slack</span>
                        </div>
                        <div className="slack-body">
                            <div className="slack-message">
                                <div className="slack-avatar">👨🏻</div>
                                <div className="slack-msg-content">
                                    <div className="slack-sender">Tobias</div>
                                    <div className="slack-text">Hey Tucean, is Smartscribe working for you?</div>
                                </div>
                            </div>
                            <div className="slack-message">
                                <div className="slack-avatar you">👩🏼</div>
                                <div className="slack-msg-content">
                                    <div className="slack-sender">You</div>
                                    <div className="slack-text">Yeah it's going well. How about you?</div>
                                </div>
                            </div>
                            <div className="slack-message">
                                <div className="slack-avatar">👨🏻</div>
                                <div className="slack-msg-content">
                                    <div className="slack-sender">Tobias</div>
                                    <div className="slack-text">It's great! I use it all the time. 😄</div>
                                </div>
                            </div>
                        </div>
                        <div className="slack-input-area">
                            <div className="slack-input-box">
                                <span>Hold down on the fn key and start speaking...</span>
                                <Send size={14} />
                            </div>
                        </div>
                    </div>
                );
            case 'email':
                return (
                    <div className="mock-card email-mock">
                        <div className="email-header">
                            <div className="email-row"><strong>To:</strong> Team</div>
                            <div className="email-row"><strong>Subject:</strong> Project Update</div>
                        </div>
                        <div className="email-body">
                            {emailContent ? (
                                <div className="markdown-content">
                                    {renderMarkdown(emailContent)}
                                </div>
                            ) : (
                                <div className="transcription-placeholder">
                                    {renderMarkdown(`Hi Team,

Here is a quick update on the project status:

- Design phase completed
- Development sprint started
- Initial user testing scheduled

Let me know if you have any questions.`)}
                                </div>
                            )}
                        </div>
                    </div>
                );
            case 'note':
                return (
                    <div className="mock-card notion-mock">
                        <div className="notion-header">
                            <img src="https://upload.wikimedia.org/wikipedia/commons/4/45/Notion_app_logo.png" className="slack-logo-icon" alt="Notion" style={{ width: 16, height: 16 }} />
                            <span className="slack-app-name">Notion</span>
                        </div>
                        <div className="notion-body">
                            <div className="notion-icon">✏️</div>
                            <div className="notion-title">New Note</div>
                            <div className="notion-content">
                                {noteContent ? (
                                    <div className="markdown-content">
                                        {renderMarkdown(noteContent)}
                                    </div>
                                ) : (
                                    <div className="transcription-placeholder">
                                        {renderMarkdown(`I want to pick up a few things from the store:
- Bread for sandwiches
- Potato chips
- Vanilla ice cream
- Sparkling water`)}
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                );
        }
    };

    const VisualContent = (
        <div className="learn-visual-wrapper">
            <div className="learn-tabs">
                <button
                    className={`learn-tab-btn ${activeTab === 'message' ? 'active' : ''}`}
                    onClick={() => setActiveTab('message')}
                >
                    {activeTab === 'message' && <Check size={14} />} Send a message
                </button>
                <button
                    className={`learn-tab-btn ${activeTab === 'email' ? 'active' : ''}`}
                    onClick={() => setActiveTab('email')}
                >
                    {activeTab === 'email' && <Check size={14} />} Draft an email
                </button>
                <button
                    className={`learn-tab-btn ${activeTab === 'note' ? 'active' : ''}`}
                    onClick={() => setActiveTab('note')}
                >
                    {activeTab === 'note' && <Check size={14} />} Whisper a note
                </button>
            </div>
            {renderVisualMock()}
        </div>
    );

    return (
        <OnboardingLayout
            currentStep={currentStep}
            totalSteps={totalSteps}
            showVisual={true}
            visualContent={VisualContent}
        >
            <div className="interactive-learn-container">
                <button
                    className="back-button-simple"
                    onClick={onSkip} // Using skip as back for now or pass dedicated onBack
                    style={{
                        alignSelf: 'flex-start',
                        background: 'none',
                        border: 'none',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        color: '#6b7280',
                        cursor: 'pointer',
                        marginBottom: '24px',
                        fontSize: '14px',
                        visibility: 'hidden' // Hide back button on this step as per design or keep it?
                        // Design has "Back" at top left.
                    }}
                >
                    ← Back
                </button>

                {renderContent()}

                <div className="learn-actions">
                    <button className="learn-continue-btn" onClick={onNext}>Continue</button>
                    <button className="learn-skip-btn" onClick={onSkip}>Skip</button>
                </div>
            </div>
        </OnboardingLayout>
    );
};
