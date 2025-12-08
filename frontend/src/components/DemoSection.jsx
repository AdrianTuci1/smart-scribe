import React from 'react';

const DemoSection = () => {
    return (
        <section className="demo-section section">
            <div className="container">
                <div className="demo-container">
                    <div className="demo-header">
                        <div className="dot red"></div>
                        <div className="dot yellow"></div>
                        <div className="dot green"></div>
                    </div>
                    <div className="demo-content">
                        <div className="chat-bubble user">
                            "Create a meeting summary for the marketing team."
                        </div>
                        <div className="processing-indicator">
                            <span>Processing...</span>
                        </div>
                        <div className="chat-bubble system">
                            <strong>Meeting Summary: Marketing Sync</strong><br />
                            - Discussed Q4 campaign strategy.<br />
                            - Approved new ad creatives.<br />
                            - Action item: Finalize budget by Friday.
                        </div>
                    </div>
                </div>
            </div>

            <style>{`
        .demo-section {
          background: linear-gradient(to bottom, var(--bg-color), #111);
        }

        .demo-container {
          max-width: 800px;
          margin: 0 auto;
          background: rgba(20, 20, 20, 0.8);
          border: 1px solid var(--card-border);
          border-radius: 12px;
          box-shadow: 0 20px 50px rgba(0,0,0,0.5);
          overflow: hidden;
          backdrop-filter: blur(10px);
        }

        .demo-header {
          background: rgba(255, 255, 255, 0.05);
          padding: 1rem;
          display: flex;
          gap: 8px;
          border-bottom: 1px solid var(--card-border);
        }

        .dot {
          width: 12px;
          height: 12px;
          border-radius: 50%;
        }

        .red { background: #ff5f56; }
        .yellow { background: #ffbd2e; }
        .green { background: #27c93f; }

        .demo-content {
          padding: 2rem;
          display: flex;
          flex-direction: column;
          gap: 1.5rem;
          min-height: 300px;
        }

        .chat-bubble {
          max-width: 80%;
          padding: 1rem 1.5rem;
          border-radius: 12px;
          font-size: 1rem;
          line-height: 1.5;
        }

        .chat-bubble.user {
          align-self: flex-end;
          background: var(--accent-color);
          color: white;
          border-bottom-right-radius: 2px;
        }

        .chat-bubble.system {
          align-self: flex-start;
          background: var(--card-bg);
          border: 1px solid var(--card-border);
          color: var(--text-primary);
          border-bottom-left-radius: 2px;
        }

        .processing-indicator {
          align-self: center;
          color: var(--text-secondary);
          font-size: 0.9rem;
          font-style: italic;
          animation: pulse 1.5s infinite;
        }

        @keyframes pulse {
          0%, 100% { opacity: 0.5; }
          50% { opacity: 1; }
        }
      `}</style>
        </section>
    );
};

export default DemoSection;
