import React, { useRef } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import './Features.css';
import FeatureSnippets from './FeatureSnippets';
import FeatureDictionary from './FeatureDictionary';
import FeatureIntegrations from './FeatureIntegrations';

const FeatureCard = ({ index, title, subtitle, description, color, visual, progress, entryRange, exitRange }) => {
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

  return (
    <motion.div
      className="feature-card-wrapper"
      style={{
        zIndex: index,
        y,
        scale,
        rotateX,
        rotateZ,
        opacity,

        transformStyle: "preserve-3d"
      }}
    >
      <motion.div
        className="feature-card"
        style={{
          backgroundColor: color,

          borderRadius,

          overflow: "hidden"
        }}
      >
        <div className="feature-card-content">
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
    <section className="features-section" ref={containerRef}>
      <div className="features-viewport">
        {features.map((feature) => (
          <FeatureCard
            key={feature.index}
            {...feature}
            progress={scrollYProgress}
          />
        ))}
      </div>
    </section>
  );
};

export default Features;
