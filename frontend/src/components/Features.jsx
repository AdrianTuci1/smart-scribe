import React, { useRef, useState, useEffect } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import './Features.css';
import FeatureSnippets from './FeatureSnippets';
import FeatureDictionary from './FeatureDictionary';
import FeatureIntegrations from './FeatureIntegrations';

const FeatureCard = ({ index, title, subtitle, description, color, visual, progress, entryRange, exitRange, isMobile }) => {
  // scale and rotation animation for the card as it "goes behind"
  const scale = useTransform(progress, exitRange, [1, 0.4]);
  const rotateX = useTransform(progress, exitRange, [0, -15]);

  // Alternate rotateZValue
  const rotateZValue = index % 2 === 0 ? -8 : 8;
  const rotateZ = useTransform(progress, exitRange, [0, rotateZValue]);

  // Opacity
  const opacity = useTransform(progress, exitRange, [1, 1]);


  // Custom mapping for snappier entry:
  // borderRadius stays 48px until the card is almost in place
  const borderRadius = useTransform(progress,
    [
      entryRange[0],
      entryRange[0] + (entryRange[1] - entryRange[0]) * 0.9,
      entryRange[1],
      exitRange[0],
      exitRange[1]
    ],
    ["48px", "0px", "0px", "0px", "48px"]
  );


  // Slide up from bottom
  const y = useTransform(progress, entryRange, ["100vh", "0vh"]);

  // Mobile checks to disable animations and enforce vertical stacking
  const cardStyle = isMobile
    ? {
      position: 'relative',
      height: 'auto',
      marginBottom: '20px',
      opacity: 1,
      // Reset transforms for mobile
      scale: 1,
      rotateX: 0,
      rotateZ: 0,
      y: 0,
      zIndex: 1, // Basic stacking
    }
    : {
      zIndex: index,
      y,
      scale,
      rotateX,
      rotateZ,
      opacity,
      backfaceVisibility: 'hidden', // Fix for mobile flickering/z-index
      WebkitBackfaceVisibility: 'hidden', // Safari prefix
      transformStyle: 'preserve-3d', // Safari fixing
      willChange: 'transform, opacity', // Performance optimization
    };

  return (
    <motion.div
      className="feature-card-wrapper"
      style={cardStyle}
    >
      <motion.div
        className="feature-card"
        style={{
          backgroundColor: color,

          borderRadius: isMobile ? '24px' : borderRadius,

          overflow: "hidden",
          // Safari fix for nested overflow radius
          maskImage: 'radial-gradient(white, black)',
          WebkitMaskImage: '-webkit-radial-gradient(white, black)',
        }}
      >
        <div className="feature-card-content max-w-[1460px] mx-auto">
          <div className="feature-card-main">
            <h1 className="feature-main-title">{title}</h1>
            <div className="feature-card-details">
              <span className="feature-index">0{index}</span>
              <div className="feature-text-group">
                <p className="feature-description">{description}</p>
              </div>
            </div>
          </div>
          <div className="feature-card-right">
            <div className="image-frame">
              {React.isValidElement(visual)
                ? React.cloneElement(visual, { progress, entryRange, exitRange })
                : visual}
            </div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
};

const Features = () => {
  const containerRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"]
  });

  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };

    // Initial check
    checkMobile();

    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const features = [
    {
      index: 1,
      title: "Library",
      subtitle: "Library, Transcriptions, Voice Notes",
      description: "Manage all your transcriptions and voice notes in one centralized, searchable library. Access your thoughts anytime, anywhere.",
      color: "#7591EE",
      visual: <FeatureSnippets />,
      entryRange: [-0.01, 0],
      exitRange: [0.15, 0.45]
    },
    {
      index: 2,
      title: "Dictionary",
      subtitle: "Dictionary, Custom Words, Industry Jargon",
      description: "Automatically learns your unique words and adds them to your personal dictionary. Smartscribe understands your industry jargon and names.",
      color: "#C5FAAB",
      visual: <FeatureDictionary />,
      entryRange: [0.15, 0.45],
      exitRange: [0.55, 0.85]
    },
    {
      index: 3,
      title: "Different Tones",
      subtitle: "Tones, Professional, Casual",
      description: "Adapt your transcription to any context. From professional reports to casual brainstorms, Smartscribe captures the right tone for your needs.",
      color: "#FADCAB",
      visual: <FeatureIntegrations />,
      entryRange: [0.55, 0.85],
      exitRange: [1.1, 1.2] // Stays in view
    }
  ];

  return (
    <section
      className="features-section w-full flex justify-center"
      ref={containerRef}
      style={{
        backgroundColor: 'transparent',
        height: isMobile ? 'auto' : '350vh' // Let it flow naturally on mobile
      }}
    >
      <div
        className="features-viewport bg-[#121212] overflow-hidden"
        style={{
          position: isMobile ? 'relative' : 'sticky',
          height: isMobile ? 'auto' : '100vh',
          display: isMobile ? 'block' : 'flex',
          padding: isMobile ? '20px 10px' : '0'
        }}
      >
        {features.map((feature) => (
          <FeatureCard
            key={feature.index}
            {...feature}
            progress={scrollYProgress}
            isMobile={isMobile}
          />
        ))}
      </div>
    </section>
  );
};

export default Features;
