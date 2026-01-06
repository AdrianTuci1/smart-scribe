import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import DownloadButton from './ui/DownloadButton';
import './Hero.css';

const EXAMPLES = [
  {
    id: 1,
    raw: (
      <>
        <span className="demo-filler">umm</span> <span className="demo-name">Sarah</span> i'll meet you at <span className="demo-strike">5pm, no</span> <span className="demo-corrected">6pm</span>
      </>
    ),
    clean: "Hey Sarah, I'll meet you at 6pm."
  },
  {
    id: 2,
    raw: (
      <>
        <span className="demo-filler">uhh</span> I <span className="demo-strike">think that</span> believe <span className="demo-name">Alex</span> is <span className="demo-strike">gonna be</span> arriving <span className="demo-corrected">late</span>
      </>
    ),
    clean: "I believe Alex is arriving late."
  },
  {
    id: 3,
    raw: (
      <>
        Let's <span className="demo-strike">try to</span> <span className="demo-filler">like</span> schedule the <span className="demo-name">Zoom</span> <span className="demo-corrected">meeting</span> for <span className="demo-strike">tuesday</span> Wednesday
      </>
    ),
    clean: "Let's schedule the Zoom meeting for Wednesday."
  }
];

const Hero = () => {
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % EXAMPLES.length);
    }, 4000);

    return () => clearInterval(timer);
  }, []);

  const currentExample = EXAMPLES[currentIndex];

  return (
    <section className="hero">
      <div className="hero-container">
        <div className="hero-content">
          <h1 className="hero-title">Smartscribe</h1>
          <p className="hero-subtitle">
            voice-to-text AI that auto corrects your speech
          </p>

          <div className="cta-wrapper">
            <DownloadButton variant="primary" />
            <p className="compatibility-text">
              For MacOS, Windows and iPhone
            </p>
          </div>
        </div>

        <div className="hero-demo">
          <div className="demo-content">
            {/* Top Bubble (Raw) */}
            <div className="demo-bubble raw-bubble">
              <div className="demo-orb"></div>
              <div className="demo-text-container">
                <AnimatePresence mode="wait">
                  <motion.p
                    key={currentExample.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    transition={{ duration: 0.3 }}
                    className="demo-text"
                  >
                    {currentExample.raw}
                  </motion.p>
                </AnimatePresence>
              </div>
            </div>

            {/* Bottom Bubble (Clean) */}
            <div className="demo-bubble clean-bubble">
              <div className="demo-text-container">
                <AnimatePresence mode="wait">
                  <motion.p
                    key={currentExample.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    transition={{ duration: 0.3, delay: 0.1 }} // Slight delay for clean text
                    className="demo-text-clean"
                  >
                    {currentExample.clean}
                  </motion.p>
                </AnimatePresence>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
