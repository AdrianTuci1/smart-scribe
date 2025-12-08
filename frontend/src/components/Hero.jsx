import React from 'react';

const Hero = () => {
    return (
        <section className="hero-section section">
            <div className="container">
                <div className="hero-content">
                    <h1 className="hero-title">
                        Stop Typing. <br />
                        <span className="text-gradient">Start Speaking.</span>
                    </h1>
                    <p className="hero-subtitle">
                        Dictation is <strong>3x faster</strong> than typing. Create notes, emails, and messages instantly with VoiceScribe.
                    </p>
                    <div className="hero-actions">
                        <button className="btn-primary">Get Started Free</button>
                        <button className="btn-secondary">View Demo</button>
                    </div>
                </div>

                <div className="hero-visual">
                    <div className="sound-wave">
                        <div className="bar"></div>
                        <div className="bar"></div>
                        <div className="bar"></div>
                        <div className="bar"></div>
                        <div className="bar"></div>
                    </div>
                </div>
            </div>

            <style>{`
        .hero-section {
          display: flex;
          align-items: center;
          min-height: 80vh;
          position: relative;
        }

        .hero-content {
          max-width: 600px;
          z-index: 2;
        }

        .hero-title {
          font-size: 4rem;
          margin-bottom: 1.5rem;
          letter-spacing: -0.02em;
        }

        .hero-subtitle {
          font-size: 1.25rem;
          color: var(--text-secondary);
          margin-bottom: 2.5rem;
          max-width: 480px;
        }

        .hero-actions {
          display: flex;
          gap: 1rem;
        }

        .btn-secondary {
          background: transparent;
          color: var(--text-primary);
          padding: 0.8rem 2rem;
          border: 1px solid var(--card-border);
          border-radius: 9999px;
          font-weight: 600;
          font-size: 1.1rem;
          transition: all 0.3s ease;
        }

        .btn-secondary:hover {
          background: rgba(255, 255, 255, 0.05);
        }

        .hero-visual {
          position: absolute;
          right: 10%;
          top: 50%;
          transform: translateY(-50%);
          z-index: 1;
        }

        .sound-wave {
          display: flex;
          align-items: center;
          gap: 6px;
          height: 100px;
        }

        .bar {
          width: 10px;
          background: var(--accent-color);
          border-radius: 9999px;
          animation: wave 1s ease-in-out infinite;
        }

        .bar:nth-child(1) { height: 40px; animation-delay: 0.0s; }
        .bar:nth-child(2) { height: 80px; animation-delay: 0.1s; }
        .bar:nth-child(3) { height: 60px; animation-delay: 0.2s; }
        .bar:nth-child(4) { height: 90px; animation-delay: 0.3s; }
        .bar:nth-child(5) { height: 50px; animation-delay: 0.4s; }

        @keyframes wave {
          0%, 100% { transform: scaleY(1); }
          50% { transform: scaleY(1.5); }
        }

        @media (max-width: 768px) {
          .hero-section {
            text-align: center;
            justify-content: center;
          }
          
          .hero-content {
            margin: 0 auto;
          }

          .hero-visual {
            display: none; /* Hide visual on mobile for simplicity or adjust */
          }

          .hero-title {
            font-size: 2.5rem;
          }

          .hero-actions {
            justify-content: center;
          }
        }
      `}</style>
        </section>
    );
};

export default Hero;
