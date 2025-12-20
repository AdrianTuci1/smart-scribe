import React, { useRef, useMemo } from 'react';
import { motion } from 'framer-motion';
import Globe from './Globe';
import './International.css';

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
                className="flex flex-col gap-6 py-8"
                animate={{ y: [0, -1000] }}
                transition={{
                    duration: speed,
                    repeat: Infinity,
                    ease: "linear"
                }}
            >
                {tripledItems.map((lang, idx) => (
                    <div key={idx} className="language-item flex items-center py-2 whitespace-nowrap">
                        <span className="text-gray-900 font-bold text-4xl md:text-5xl">{lang.name}</span>
                    </div>
                ))}
            </motion.div>
        </div>
    );
};



const International = () => {
    const containerRef = useRef(null);

    return (
        <section className="international-section bg-purple-200 relative min-h-[100vh] flex items-center overflow-hidden" ref={containerRef}>


            <div className="container mx-auto px-6 grid grid-cols-1 md:grid-cols-2 gap-24 relative z-10">
                {/* Left Column: Single Scrolling Column */}
                <div className="relative h-[700px] flex justify-center overflow-hidden mask-fade-y max-w-sm mx-auto md:mx-0">
                    <ScrollingColumn items={LANGUAGES} speed={40} />
                </div>

                {/* Right Column: Globe and Text - Pushed more to the edge */}
                <div className="flex flex-col justify-center items-center md:items-end text-center md:text-left space-y-12 pr-0 md:pr-12">
                    <div className="space-y-6">
                        <h2 className="text-5xl md:text-5xl font-black text-gray-900 leading-tight">
                            We support 100+ languages
                        </h2>
                        <p className="text-gray-500 text-xl md:text-xl font-medium max-w-xl ml-auto">
                            Effortless transcription and translation across the globe. Breaking barriers in every conversation.
                        </p>
                    </div>

                    {/* Globe */}
                    <div className="globe-container relative w-80 h-80 md:w-[600px] md:h-[600px]">
                        <Globe className="absolute inset-0" />
                    </div>
                </div>
            </div>
        </section>
    );
};

export default International;
