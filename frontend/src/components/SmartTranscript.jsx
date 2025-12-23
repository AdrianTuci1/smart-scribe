import React, { useState, useEffect, useRef, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import './SmartTranscript.css';

const TRANSCRIPT_GROUPS = [
    {
        id: 'group1',
        title: 'Înregistrare 1',
        data: [
            { id: 1, text: "Hey, ", type: 'default' },
            { id: 2, text: "I'm ", type: 'default' },
            { id: 3, text: "here ", type: 'default' },
            { id: 4, text: "with, ", type: 'default' },
            { id: 5, text: "uhm, ", type: 'strike' },
            { id: 6, text: "Sarah, ", type: 'chip', color: 'bg-purple-600', tag: 'fixed spelling' },
            { id: 7, text: "and ", type: 'default' },
            { id: 8, text: "we ", type: 'default' },
            { id: 9, text: "just ", type: 'default' },
            { id: 10, text: "finished ", type: 'default' },
            { id: 11, text: "at ", type: 'default' },
            { id: 12, text: "the ", type: 'default' },
            { id: 13, text: "office ", type: 'chip', color: 'bg-blue-600', tag: 'took from snippets' },
            { id: 14, text: "on... ", type: 'default' },
            { id: 15, text: "uh... ", type: 'strike' },
            { id: 16, text: "Baker ", type: 'default' },
            { id: 17, text: "Street. ", type: 'default' },
            { id: 18, text: "We're ", type: 'default' },
            { id: 19, text: "walking ", type: 'default' },
            { id: 20, text: "to ", type: 'default' },
            { id: 21, text: "the ", type: 'default' },
            { id: 22, text: "restaurant ", type: 'default' },
            { id: 23, text: "now—", type: 'default' },
            { id: 24, text: "actually, ", type: 'strike', tag: 'removed filler' },
            { id: 25, text: "no, ", type: 'strike' },
            { id: 26, text: "we're ", type: 'default' },
            { id: 27, text: "taking ", type: 'default' },
            { id: 28, text: "a ", type: 'default' },
            { id: 29, text: "taxi ", type: 'chip', color: 'bg-yellow-600' },
            { id: 30, text: "because ", type: 'default' },
            { id: 31, text: "it's ", type: 'default' },
            { id: 32, text: "raining. ", type: 'default' },
            { id: 33, text: "We ", type: 'default' },
            { id: 34, text: "should ", type: 'default' },
            { id: 35, text: "be ", type: 'default' },
            { id: 36, text: "at ", type: 'default' },
            { id: 37, text: "the ", type: 'default' },
            { id: 38, text: "The ", type: 'default' },
            { id: 39, text: "Silver ", type: 'default' },
            { id: 40, text: "Grill ", type: 'chip', color: 'bg-green-600', tag: 'fixed spelling' },
            { id: 41, text: "by ", type: 'default' },
            { id: 42, text: "7:15... ", type: 'strike' },
            { id: 43, text: "wait, ", type: 'strike' },
            { id: 44, text: "I ", type: 'strike' },
            { id: 45, text: "mean ", type: 'strike' },
            { id: 46, text: "7:30. ", type: 'chip', color: 'bg-orange-600' },
            { id: 47, text: "Traffic ", type: 'default' },
            { id: 48, text: "is ", type: 'default' },
            { id: 49, text: "bad. ", type: 'default' },
            { id: 50, text: "Just ", type: 'default' },
            { id: 51, text: "in ", type: 'default' },
            { id: 52, text: "case ", type: 'default' },
            { id: 53, text: "Stephan ", type: 'default' },
            { id: 54, text: "asks, ", type: 'default' },
            { id: 55, text: "here’s ", type: 'default' },
            { id: 56, text: "my ", type: 'default' },
            { id: 57, text: "website: ", type: 'default' },
            { id: 58, text: "marystale.dev ", type: 'chip', color: 'bg-cyan-600', tag: 'added to dictionary' },
            { id: 59, text: "See ", type: 'default' },
            { id: 60, text: "you ", type: 'default' },
            { id: 61, text: "there!", type: 'default' },
        ]
    },
    {
        id: 'group2',
        title: 'Înregistrare 2',
        data: [
            { id: 62, text: "So, ", type: 'default' },
            { id: 63, text: "I'm ", type: 'default' },
            { id: 64, text: "meeting ", type: 'default' },
            { id: 65, text: "with... ", type: 'default' },
            { id: 66, text: "uh... ", type: 'strike' },
            { id: 67, text: "David, ", type: 'chip', color: 'bg-teal-600', tag: 'took from snippets' },
            { id: 68, text: "at ", type: 'default' },
            { id: 69, text: "that ", type: 'default' },
            { id: 70, text: "small ", type: 'default' },
            { id: 71, text: "café ", type: 'default' },
            { id: 72, text: "near... ", type: 'default' },
            { id: 73, text: "uhm... ", type: 'strike' },
            { id: 74, text: "Central ", type: 'default' },
            { id: 75, text: "Park. ", type: 'chip', color: 'bg-pink-600', tag: 'fixed spelling' },
            { id: 76, text: "We're ", type: 'default' },
            { id: 77, text: "going ", type: 'default' },
            { id: 78, text: "to ", type: 'default' },
            { id: 79, text: "discuss ", type: 'default' },
            { id: 80, text: "the ", type: 'default' },
            { id: 81, text: "project—", type: 'default' },
            { id: 82, text: "well, ", type: 'strike', tag: 'removed filler' },
            { id: 83, text: "actually, ", type: 'strike' },
            { id: 84, text: "we're ", type: 'default' },
            { id: 85, text: "mostly ", type: 'default' },
            { id: 86, text: "just ", type: 'default' },
            { id: 87, text: "catching ", type: 'default' },
            { id: 88, text: "up. ", type: 'default' },
            { id: 89, text: "We'll ", type: 'default' },
            { id: 90, text: "probably ", type: 'default' },
            { id: 91, text: "be ", type: 'default' },
            { id: 92, text: "there ", type: 'default' },
            { id: 93, text: "until ", type: 'default' },
            { id: 94, text: "4:45... ", type: 'strike' },
            { id: 95, text: "no, ", type: 'strike', tag: 'removed filler' },
            { id: 96, text: "I ", type: 'strike' },
            { id: 97, text: "meant ", type: 'strike' },
            { id: 98, text: "5:15. ", type: 'chip', color: 'bg-rose-600' },
            { id: 99, text: "If ", type: 'default' },
            { id: 100, text: "anyone ", type: 'default' },
            { id: 101, text: "needs ", type: 'default' },
            { id: 102, text: "me, ", type: 'default' },
            { id: 103, text: "you ", type: 'default' },
            { id: 104, text: "can ", type: 'default' },
            { id: 105, text: "check ", type: 'default' },
            { id: 106, text: "my ", type: 'default' },
            { id: 107, text: "portfolio: ", type: 'default' },
            { id: 108, text: "davedesigns.io ", type: 'chip', color: 'bg-emerald-600', tag: 'took from snippets' },
            { id: 109, text: "talk ", type: 'default' },
            { id: 110, text: "soon!", type: 'default' },
        ]
    }
];

const TranscriptItem = ({ item, containerRef }) => {
    const [isProcessed, setIsProcessed] = useState(false);
    const elementRef = useRef(null);

    // Random rotation for the tag: -10deg, 0deg, or 10deg
    const rotation = useMemo(() => {
        const rand = Math.random();
        if (rand < 0.33) return -10;
        if (rand < 0.66) return 10;
        return 0;
    }, []);

    useEffect(() => {
        if (!containerRef?.current || !elementRef.current) return;

        const observer = new IntersectionObserver(
            ([entry]) => {
                setIsProcessed(entry.isIntersecting);
            },
            {
                root: containerRef.current,
                rootMargin: "0px 0px -50% 0px",
                threshold: 0
            }
        );

        observer.observe(elementRef.current);

        return () => observer.disconnect();
    }, [containerRef]);

    const getStyle = () => {
        // If not processed, show as default regular text (white, no chips, no strikes)
        if (!isProcessed) {
            return 'inline-block text-white opacity-90 transition-all duration-300';
        }

        switch (item.type) {
            case 'chip':
                // Chip style activates only when processed
                return `inline-block px-3 py-1 rounded-md text-white ${item.color || 'bg-accent-color'} font-medium shadow-sm transition-all duration-300 hover:scale-105`;
            case 'strike':
                // Strike style: text becomes gray
                return 'inline-block text-gray-500 transition-colors duration-300 mx-0.5 relative';
            default:
                return 'inline-block text-white opacity-90 transition-opacity duration-300 hover:opacity-100';
        }
    };

    return (
        <div ref={elementRef} className="relative inline-block align-middle group">
            {/* Tag rendering */}
            {item.tag && (
                <motion.div
                    initial={{ opacity: 0, y: 10, scale: 0.8, x: "-50%" }}
                    animate={isProcessed ? { opacity: 1, y: 0, scale: 1, x: "-50%" } : { opacity: 0, y: 10, scale: 0.8, x: "-50%" }}
                    transition={{ duration: 0.4, ease: "easeOut" }}
                    className="tag-motion-container"
                >
                    <div className="tag-rotator" style={{ transform: `rotate(${rotation}deg)` }}>
                        <div className="correction-tag">
                            {item.tag}
                        </div>
                    </div>
                </motion.div>
            )}

            <span className={getStyle()}>
                {item.text}
                {/* Animated strikethrough line - Gray color */}
                {item.type === 'strike' && (
                    <motion.span
                        initial={{ width: "0%" }}
                        animate={isProcessed ? { width: "100%" } : { width: "0%" }}
                        transition={{ duration: 0.3, ease: "easeInOut" }}
                        className="absolute left-0 top-1/2 h-[2px] bg-gray-500 -translate-y-1/2 pointer-events-none"
                    />
                )}
            </span>
        </div>
    );
};

const SmartTranscript = () => {
    // Duplicate for infinite loop
    const loopedGroups = [...TRANSCRIPT_GROUPS, ...TRANSCRIPT_GROUPS, ...TRANSCRIPT_GROUPS, ...TRANSCRIPT_GROUPS];
    const containerRef = useRef(null);

    return (
        <section className="smart-transcript-section overflow-hidden flex justify-center py-20">
            {/* Reduced height from 600px to 400px */}
            <div
                ref={containerRef}
                className="transcript-main-container bg-[#1f1d1d] relative w-full h-[440px] overflow-hidden flex flex-col items-center justify-center mask-gradient"
            >
                {/* Masking Gradient Layer */}
                <div className="absolute inset-0 pointer-events-none z-30"
                    style={{ background: 'linear-gradient(to bottom, #1f1d1d 0%, transparent 15%, transparent 85%, #1f1d1d 100%)' }}>
                </div>

                {/* Scanner/Separator Line - Thicker, centered, slightly wider than text (480px vs 400px) */}
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 w-[480px] h-[2px] z-20 pointer-events-none">
                    <div className="w-full h-full bg-orange-500/50 shadow-[0_0_12px_rgba(249,115,22,0.4)] rounded-full"></div>
                </div>

                <motion.div
                    animate={{ y: [0, -1200] }}
                    transition={{
                        duration: 45,
                        repeat: Infinity,
                        ease: "linear"
                    }}
                    className="flex flex-col gap-10 w-full items-center z-10 pt-20"
                >
                    {loopedGroups.map((group, index) => (
                        <div key={`${group.id}-${index}`} className="transcript-box rounded-xl max-w-[400px] w-full px-4">
                            <div className="transcript-container flex flex-wrap justify-start items-center gap-x-1.5 gap-y-3 leading-relaxed text-left text-base">
                                {group.data.map((item, i) => (
                                    <TranscriptItem
                                        key={`${item.id}-${index}-${i}`}
                                        item={item}
                                        containerRef={containerRef}
                                    />
                                ))}
                            </div>
                        </div>
                    ))}
                </motion.div>
            </div>
        </section>
    );
};

export default SmartTranscript;
