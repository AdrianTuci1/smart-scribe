import React, { useRef, useMemo, useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import './International.css';



const useWindowSize = () => {
    const [windowSize, setWindowSize] = useState({
        width: typeof window !== 'undefined' ? window.innerWidth : 0,
    });

    useEffect(() => {
        const handleResize = () => {
            setWindowSize({
                width: window.innerWidth,
            });
        };

        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

    return windowSize;
};




const LANGUAGES = [
    { name: 'English' },
    { name: 'Romanian' },
    { name: 'French' },
    { name: 'German' },
    { name: 'Spanish' },
    { name: 'Italian' },
    { name: 'Portuguese' },
    { name: 'Dutch' },
    { name: 'Polish' },
    { name: 'Russian' },
    { name: 'Japanese' },
    { name: 'Korean' },
    { name: 'Chinese' },
    { name: 'Hindi' },
    { name: 'Arabic' },
    { name: 'Turkish' },
    { name: 'Greek' },
    { name: 'Swedish' },
    { name: 'Danish' },
    { name: 'Finnish' },
];

const ScrollingColumn = ({ items, speed = 14 }) => {
    // Triple the items for seamless infinite scroll
    const tripledItems = [...items, ...items, ...items];

    return (
        <div className="scrolling-column-container h-full overflow-hidden relative">
            <motion.div
                className="flex flex-col gap-6"
                animate={{ y: [0, -1000] }}
                transition={{
                    duration: speed,
                    repeat: Infinity,
                    ease: "linear"
                }}
            >
                {tripledItems.map((lang, idx) => (
                    <div key={idx} className="flex items-center whitespace-nowrap cursor-default transition-all duration-400 ease-[cubic-bezier(0.175,0.885,0.32,1.275)]">
                        <span className="text-gray-900 font-bold text-6xl md:text-7xl">{lang.name}</span>
                    </div>
                ))}
            </motion.div>
        </div>
    );
};



import GlobeThree from './GlobeThree';
import TryButton from './ui/TryButton';
import DownloadButton from './ui/DownloadButton';

// ... (keep existing imports)

// ... (keep useWindowSize)

// ... (keep LANGUAGES and ScrollingColumn)

const International = () => {
    const containerRef = useRef(null);
    const { width } = useWindowSize();
    const isMobile = width < 768; // md breakpoint is 768px
    const horizontalPadding = isMobile ? '10px' : '75px';


    return (
        <section className="bg-purple-200 relative pt-1 pb-0 overflow-hidden transition-colors duration-500 ease-out h-full w-full flex justify-center" ref={containerRef}>

            <div
                className="w-full relative z-10 h-full flex flex-col lg:grid lg:grid-cols-2 gap-10 lg:gap-24 max-w-[1460px] mx-auto"
                style={{ paddingLeft: horizontalPadding, paddingRight: horizontalPadding }}
            >

                {/* 1. Text Section - Order 1 on Mobile */}
                <div className="order-1 lg:order-2 lg:col-start-2 relative z-10 pt-10 lg:pt-48 pointer-events-none text-left lg:pr-12" style={{ paddingTop: '24px' }}>
                    <h2 className="text-5xl md:text-5xl font-black text-gray-900 leading-tight tracking-[-0.02em]">
                        We support 100+ languages
                    </h2>
                    <p className="text-gray-500 text-xl md:text-xl font-medium max-w-xl md:ml-0 leading-[1.6] pt-4">
                        Effortless transcription and translation across the globe. Breaking barriers in every conversation.
                    </p>
                    <div className="international-buttons">
                        <TryButton variant="outline" className="border-gray-900 text-gray-900 hover:bg-white/50" />
                        <DownloadButton variant="primary" className="bg-gray-900 text-white hover:bg-gray-800" />
                    </div>
                </div>

                {/* 2. Scrolling Column - Order 2 on Mobile */}
                <div className="order-2 lg:order-1 lg:col-start-1 relative h-[500px] lg:h-[700px] flex justify-center overflow-hidden mask-fade-y max-w-sm mx-auto md:mx-0">
                    <ScrollingColumn items={LANGUAGES} speed={40} />
                </div>

                <div className="absolute bottom-0 left-0 w-full flex justify-center md:justify-end translate-y-[50%] z-0 pointer-events-none overflow-hidden md:pr-[10%]">
                    <GlobeThree isMobile={isMobile} />
                </div>
            </div>
        </section>
    );
};

export default International;
