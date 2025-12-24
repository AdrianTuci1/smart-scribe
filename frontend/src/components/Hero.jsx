import React from 'react';
import DownloadButton from './ui/DownloadButton';
import './Hero.css';

const Hero = () => {
  return (
    <section className="hero">
      <div className="hero-container">
        <div className="hero-left">
          <h1 className="hero-title">Smartscribe</h1>
          <p className="hero-subtitle">
            voice-to-text AI that auto corrects your speech
          </p>
        </div>

        <div className="hero-right">
          <div className="cta-wrapper">
            <DownloadButton variant="primary" />
            <p className="compatibility-text">
              For MacOS, Windows and iPhone
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
