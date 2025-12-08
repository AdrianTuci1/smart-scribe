import React from 'react';

const Footer = () => {
    return (
        <footer className="footer-section">
            <div className="container">
                <div className="footer-content">
                    <div className="footer-brand">
                        <h3>VoiceScribe</h3>
                        <p>Your voice, perfectly transcribed.</p>
                    </div>
                    <div className="footer-links">
                        <a href="#">Privacy</a>
                        <a href="#">Terms</a>
                        <a href="#">Contact</a>
                    </div>
                </div>
                <div className="footer-bottom">
                    <p>&copy; {new Date().getFullYear()} VoiceScribe. All rights reserved.</p>
                </div>
            </div>

            <style>{`
        .footer-section {
          background: #050505;
          padding: 4rem 0 2rem;
          border-top: 1px solid var(--card-border);
          margin-top: 4rem;
        }

        .footer-content {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 2rem;
        }

        .footer-brand h3 {
          font-size: 1.5rem;
          margin-bottom: 0.5rem;
        }

        .footer-brand p {
          color: var(--text-secondary);
        }

        .footer-links {
          display: flex;
          gap: 2rem;
        }

        .footer-links a {
          color: var(--text-secondary);
        }

        .footer-links a:hover {
          color: var(--accent-color);
        }

        .footer-bottom {
          text-align: center;
          padding-top: 2rem;
          border-top: 1px solid var(--card-border);
          color: var(--text-secondary);
          font-size: 0.9rem;
        }

        @media (max-width: 768px) {
          .footer-content {
            flex-direction: column;
            gap: 2rem;
            text-align: center;
          }
        }
      `}</style>
        </footer>
    );
};

export default Footer;
