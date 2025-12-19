import React, { useState, useEffect } from 'react';
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
            { id: 6, text: "Sarah, ", type: 'chip', color: 'bg-purple-600' },
            { id: 7, text: "and ", type: 'default' },
            { id: 8, text: "we ", type: 'default' },
            { id: 9, text: "just ", type: 'default' },
            { id: 10, text: "finished ", type: 'default' },
            { id: 11, text: "at ", type: 'default' },
            { id: 12, text: "the ", type: 'default' },
            { id: 13, text: "office ", type: 'chip', color: 'bg-blue-600' },
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
            { id: 24, text: "actually, ", type: 'strike' },
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
            { id: 40, text: "Grill ", type: 'chip', color: 'bg-green-600' },
            { id: 41, text: "by ", type: 'default' },
            { id: 42, text: "7:15... ", type: 'strike' },
            { id: 43, text: "wait, ", type: 'strike' },
            { id: 44, text: "I ", type: 'default' },
            { id: 45, text: "mean ", type: 'default' },
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
            { id: 58, text: "marystale.dev ", type: 'chip', color: 'bg-cyan-600' },
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
            { id: 67, text: "David, ", type: 'chip', color: 'bg-teal-600' },
            { id: 68, text: "at ", type: 'default' },
            { id: 69, text: "that ", type: 'default' },
            { id: 70, text: "small ", type: 'default' },
            { id: 71, text: "café ", type: 'default' },
            { id: 72, text: "near... ", type: 'default' },
            { id: 73, text: "uhm... ", type: 'strike' },
            { id: 74, text: "Central ", type: 'default' },
            { id: 75, text: "Park. ", type: 'chip', color: 'bg-pink-600' },
            { id: 76, text: "We're ", type: 'default' },
            { id: 77, text: "going ", type: 'default' },
            { id: 78, text: "to ", type: 'default' },
            { id: 79, text: "discuss ", type: 'default' },
            { id: 80, text: "the ", type: 'default' },
            { id: 81, text: "project—", type: 'default' },
            { id: 82, text: "well, ", type: 'strike' },
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
            { id: 95, text: "no, ", type: 'strike' },
            { id: 96, text: "I ", type: 'default' },
            { id: 97, text: "meant ", type: 'default' },
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
            { id: 108, text: "davedesigns.io ", type: 'chip', color: 'bg-emerald-600' },
            { id: 109, text: "talk ", type: 'default' },
            { id: 110, text: "soon!", type: 'default' },
        ]
    }
];

const TranscriptItem = ({ item }) => {
    const [isVisible, setIsVisible] = useState(true);

    useEffect(() => {
        if (item.type === 'strike') {
            const timer = setTimeout(() => {
                setIsVisible(false);
            }, 2000);
            return () => clearTimeout(timer);
        }
    }, [item.type]);

    const getStyle = () => {
        switch (item.type) {
            case 'chip':
                return `inline-block px-3 py-1 rounded-md text-white ${item.color || 'bg-accent-color'} font-medium shadow-sm`;
            case 'strike':
                return 'inline-block text-gray-400 line-through transition-all duration-500';
            default:
                return 'inline-block text-white opacity-90';
        }
    };

    return (
        <AnimatePresence>
            {isVisible && (
                <motion.span
                    layout
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{
                        width: 0,
                        opacity: 0,
                        scale: 0,
                        margin: 0,
                        padding: 0,
                        transition: { duration: 0.5, delay: 0.2 }
                    }}
                    className="relative inline-block align-middle"
                >
                    <span className={getStyle()}>
                        {item.text.trim()}
                    </span>
                </motion.span>
            )}
        </AnimatePresence>
    );
};

const SmartTranscript = () => {
    // Duplicate for infinite loop
    const loopedGroups = [...TRANSCRIPT_GROUPS, ...TRANSCRIPT_GROUPS, ...TRANSCRIPT_GROUPS, ...TRANSCRIPT_GROUPS];

    return (
        <section className="smart-transcript-section overflow-hidden flex justify-center">
            <div className="transcript-main-container bg-[#1f1d1d] relative w-full h-[500px] overflow-hidden flex flex-col items-center justify-center">
                {/* Masking Gradient Layer */}
                <div className="absolute inset-0 pointer-events-none z-20"
                    style={{ background: 'linear-gradient(to bottom, #1f1d1d 0%, transparent 20%, transparent 80%, #1f1d1d 100%)' }}>
                </div>

                <motion.div
                    animate={{ y: [0, -1000] }}
                    transition={{
                        duration: 30,
                        repeat: Infinity,
                        ease: "linear"
                    }}
                    className="flex flex-col gap-10 w-full items-center z-10"
                >
                    {loopedGroups.map((group, index) => (
                        <div key={`${group.id}-${index}`} className="transcript-box rounded-xl max-w-[350px] w-full">
                            <div className="transcript-container flex flex-wrap justify-start items-center gap-x-2 gap-y-3 leading-relaxed text-left">
                                {group.data.map((item) => (
                                    <TranscriptItem key={`${item.id}-${index}`} item={item} />
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
