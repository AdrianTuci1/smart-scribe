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
                    className="bg-[#FFF8E7] text-black px-8 py-3 rounded-full text-2xl font-bold border-2 border-[#FFF8E7] z-10 flex items-center gap-2"
                >
                    <div className="flex gap-1 h-6 items-center">
                        <div className="w-1 h-3 bg-black rounded-full"></div>
                        <div className="w-1 h-5 bg-black rounded-full"></div>
                        <div className="w-1 h-4 bg-black rounded-full"></div>
                        <div className="w-1 h-2 bg-black rounded-full"></div>
                    </div>
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
                        <div className="w-[80px] h-[80px] bg-white rounded-2xl flex items-center justify-center shadow-lg">
                            <svg viewBox="0 0 24 24" className="w-12 h-12">
                                <path fill="#EA4335" d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zM4 6h16v.01L12 13 4 6.01V6z" />
                            </svg>
                        </div>
                        <span className="text-[#E6A055] text-xl font-bold">Hello.</span>
                    </motion.div>

                    {/* Slack */}
                    <motion.div style={{ y: yIcon, scale: scaleIcon, opacity: opacityIcon }} className="flex flex-col items-center gap-4">
                        <div className="w-[80px] h-[80px] bg-white rounded-2xl flex items-center justify-center shadow-lg">
                            <svg viewBox="0 0 24 24" className="w-12 h-12">
                                <path fill="#E01E5A" d="M6 15a2 2 0 0 1-2 2 2 2 0 0 1-2-2 2 2 0 0 1 2-2h2v2zm1 0a2 2 0 0 1 2 2v2a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-2h2zm0-1h-2a2 2 0 0 1-2-2 2 2 0 0 1 2-2 2 2 0 0 1 2 2v2zm-1-6a2 2 0 0 1 2-2h2a2 2 0 0 1-2 2 2 2 0 0 1-2-2 2 2 0 0 1 0 2z" />
                                <path fill="#36C5F0" d="M15 6a2 2 0 0 1 2-2 2 2 0 0 1 2 2 2 2 0 0 1-2 2h-2V6zm-1 0a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2 2 2 0 0 1 2 2v2h-2zm0 1h2a2 2 0 0 1 2 2 2 2 0 0 1-2 2 2 2 0 0 1-2-2V7zm1 6a2 2 0 0 1-2 2h-2a2 2 0 0 1 2-2 2 2 0 0 1 2-2 2 2 0 0 1 0 2z" />
                                <path fill="#2EB67D" d="M18 15a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-2v-2a2 2 0 0 1 2-2zm-1 0a2 2 0 0 1-2-2v-2a2 2 0 0 1 2-2 2 2 0 0 1 2 2v2h2zm0 1h-2a2 2 0 0 1-2-2 2 2 0 0 1 2-2v2z" />
                                <path fill="#ECB22E" d="M9 9a2 2 0 0 1-2 2v2a2 2 0 0 1-2-2 2 2 0 0 1 2-2h2zm1 0a2 2 0 0 1 2-2V5a2 2 0 0 1-2-2 2 2 0 0 1-2 2v2h2z" />
                            </svg>
                        </div>
                        <span className="text-[#FFE4BC] text-xl font-bold">Hello</span>
                    </motion.div>

                    {/* iMessage */}
                    <motion.div style={{ y: yIcon, scale: scaleIcon, opacity: opacityIcon }} className="flex flex-col items-center gap-4">
                        <div className="w-[80px] h-[80px] bg-[#4ADE80] rounded-2xl flex items-center justify-center shadow-lg">
                            <svg viewBox="0 0 24 24" className="w-14 h-14 text-white fill-current">
                                <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z" />
                            </svg>
                        </div>
                        <span className="text-[#FFF8E7] text-xl font-bold">hello</span>
                    </motion.div>

                </div>
            </div>
        </div>
    );
};

export default FeatureIntegrations;
