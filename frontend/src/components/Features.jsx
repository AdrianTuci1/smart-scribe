import React from 'react';

const Features = () => {
    const features = [
        {
            title: "Instant Notes",
            description: "Capture thoughts instantly. Just speak, and we'll format it into a clean note.",
            icon: "📝"
        },
        {
            title: "Smart Emails",
            description: "Draft professional emails by voice. We handle the structure and tone.",
            icon: "📧"
        },
        {
            title: "Quick Messages",
            description: "Send messages faster than you can type. Perfect for on-the-go communication.",
            icon: "💬"
        },
        {
            title: "Auto Correction",
            description: "Grammar and spelling are fixed automatically. Sound professional every time.",
            icon: "✨"
        },
        {
            title: "Live Translation",
            description: "Speak in your language, output in another. Break language barriers instantly.",
            icon: "🌐"
        }
    ];

    return (
        <section className="features-section section">
            <div className="container">
                <div className="section-header">
                    <h2 className="section-title">Everything you need to <span className="text-gradient">communicate better.</span></h2>
                    <p className="section-subtitle">Powerful features designed to boost your productivity.</p>
                </div>

                <div className="features-grid">
                    {features.map((feature, index) => (
                        <div className="feature-card" key={index}>
                            <div className="feature-icon">{feature.icon}</div>
                            <h3 className="feature-title">{feature.title}</h3>
                            <p className="feature-description">{feature.description}</p>
                        </div>
                    ))}
                </div>
            </div>

            <style>{`
        .section-header {
          text-align: center;
          margin-bottom: 4rem;
        }

        .section-title {
          font-size: 2.5rem;
          margin-bottom: 1rem;
        }

        .section-subtitle {
          color: var(--text-secondary);
          font-size: 1.1rem;
        }

        .features-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: 2rem;
        }

        .feature-card {
          background: var(--card-bg);
          border: 1px solid var(--card-border);
          padding: 2rem;
          border-radius: 16px;
          transition: transform 0.3s ease, border-color 0.3s ease;
        }

        .feature-card:hover {
          transform: translateY(-5px);
          border-color: var(--accent-color);
        }

        .feature-icon {
          font-size: 2.5rem;
          margin-bottom: 1.5rem;
        }

        .feature-title {
          font-size: 1.25rem;
          margin-bottom: 0.5rem;
        }

        .feature-description {
          color: var(--text-secondary);
          font-size: 0.95rem;
        }
      `}</style>
        </section>
    );
};

export default Features;
