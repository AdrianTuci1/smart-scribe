import React from 'react';
import { motion, useTransform } from 'framer-motion';

const FeatureIntegrations = ({ progress, entryRange }) => {
    const start = entryRange[0];
    const end = entryRange[1];

    // Animation for the "hello" chip
    const yChip = useTransform(progress, [start, end], [-50, 0]);
    const opacityChip = useTransform(progress, [start, end], [0, 1]);

    // Animation for icons (staggered and slide up)
    const yIcon = useTransform(progress, [start, end], [50, 0]);
    const scaleIcon = useTransform(progress, [start, end], [0.5, 1]);
    const opacityIcon = useTransform(progress, [start, end], [0, 1]);

    // Line drawing animation
    // Map progress to 0-1 for path length
    const pathLength = useTransform(progress, [start, end], [0, 1]);

    return (
        <div className="w-full h-full bg-[#151516] flex flex-col items-center justify-center p-8 relative overflow-hidden">

            <div className="relative w-[400px] h-[400px] flex flex-col items-center scale-[0.80] sm:scale-100 origin-center">

                {/* Top Chip */}
                <motion.div
                    style={{ y: yChip, opacity: opacityChip }}
                    className="bg-[#FFF8E7] text-black px-8 py-3 rounded-full text-2xl font-bold border-2 border-[#FFF8E7] z-10 flex items-center gap-3"
                >
                    {/* Orb Animation (Inline Style to match TryNow.css) */}
                    <style>
                        {`
                            @keyframes wave-gradient-mini {
                                0% { background-position: 0% 50%; }
                                50% { background-position: 100% 50%; }
                                100% { background-position: 0% 50%; }
                            }
                            .mini-orb {
                                background: linear-gradient(45deg, #4A4AFE, #a855f7, #4A4AFE);
                                background-size: 200% 200%;
                                animation: wave-gradient-mini 4s ease infinite;
                            }
                        `}
                    </style>
                    <div className="w-6 h-6 rounded-full mini-orb shadow-sm"></div>
                    hello
                </motion.div>

                {/* Connecting Lines */}
                <svg className="absolute top-[30px] left-0 w-full h-[250px] z-0 pointer-events-none" overflow="visible">
                    {/* Left Line */}
                    <motion.path
                        d="M200,30 C200,90 50,90 50,160"
                        fill="none"
                        stroke="#FFF8E7"
                        strokeWidth="4"
                        style={{ pathLength }}
                    />
                    {/* Center Line */}
                    <motion.path
                        d="M200,30 L200,160"
                        fill="none"
                        stroke="#FFF8E7"
                        strokeWidth="4"
                        style={{ pathLength }}
                    />
                    {/* Right Line */}
                    <motion.path
                        d="M200,30 C200,90 350,90 350,160"
                        fill="none"
                        stroke="#FFF8E7"
                        strokeWidth="4"
                        style={{ pathLength }}
                    />
                </svg>

                {/* Icons Row */}
                <div className="absolute top-[190px] w-full flex justify-between items-start px-[10px]">

                    {/* Gmail */}
                    <motion.div style={{ y: yIcon, scale: scaleIcon, opacity: opacityIcon }} className="flex flex-col items-center gap-4">
                        <div className="w-[80px] h-[80px] bg-white rounded-2xl flex items-center justify-center shadow-lg integration-logo-wrapper gmail-wrapper" style={{ padding: '4px' }}>
                            <img src="/logos/gmail.png" alt="Gmail" className="w-full h-full object-contain" />
                        </div>
                        <span className="text-[#E6A055] text-xl font-bold">Hello.</span>
                    </motion.div>

                    {/* Slack */}
                    <motion.div style={{ y: yIcon, scale: scaleIcon, opacity: opacityIcon }} className="flex flex-col items-center gap-4">
                        <div className="w-[80px] h-[80px] bg-white rounded-2xl flex items-center justify-center shadow-lg integration-logo-wrapper slack-wrapper" style={{ padding: '4px' }}>
                            <img src="/logos/slack.png" alt="Slack" className="w-full h-full object-contain" />
                        </div>
                        <span className="text-[#FFE4BC] text-xl font-bold">Hello</span>
                    </motion.div>

                    {/* Apple Messages */}
                    <motion.div style={{ y: yIcon, scale: scaleIcon, opacity: opacityIcon }} className="flex flex-col items-center gap-4">
                        <div className="w-[80px] h-[80px] bg-white rounded-2xl flex items-center justify-center shadow-lg integration-logo-wrapper imessage-wrapper">
                            <img src="/logos/imessage.png" alt="iMessage" className="w-full h-full object-contain" />
                        </div>
                        <span className="text-[#FFF8E7] text-xl font-bold">hello</span>
                    </motion.div>

                </div>
            </div>
        </div>
    );
};

export default FeatureIntegrations;
