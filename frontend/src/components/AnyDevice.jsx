import React from 'react';
import { motion } from 'framer-motion';
import DeviceMockup from './DeviceMockup';
import './AnyDevice.css';
import TryButton from './ui/TryButton';
import DownloadButton from './ui/DownloadButton';

const AnyDevice = () => {
    return (
        <section className="any-device bg-[#121212]">
            <div className="any-device-container max-w-[1460px] mx-auto">
                <div className="any-device-content">
                    <motion.div
                        className="any-device-left"
                        initial={{ opacity: 0, x: -20 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.8, ease: "easeOut" }}
                    >
                        <div className="mockup-wrapper">
                            <DeviceMockup />
                        </div>
                    </motion.div>

                    <motion.div
                        className="any-device-right"
                        initial={{ opacity: 0, x: 20 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.8, ease: "easeOut", delay: 0.2 }}
                    >
                        <h2 className="any-device-title">
                            Create without <br /> boundaries.
                        </h2>
                        <p className="any-device-description">
                            Whether you're in the office or out in the world, Smartscribe follows your lead. With real-time syncing of your notes and personal vocabulary, your workspace is wherever you happen to be.
                        </p>
                        <div className="any-device-buttons">
                            <TryButton variant="outline-white" />
                            <DownloadButton variant="primary" />
                        </div>
                    </motion.div>
                </div>
            </div>
        </section>
    );
};

export default AnyDevice;
