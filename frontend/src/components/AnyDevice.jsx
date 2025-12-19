import React from 'react';
import { motion } from 'framer-motion';
import './AnyDevice.css';
import deviceMockup from '../assets/any-device-mockup.png';

const AnyDevice = () => {
    return (
        <section className="any-device">
            <div className="any-device-container">
                <div className="any-device-content">
                    <motion.div
                        className="any-device-left"
                        initial={{ opacity: 0, x: -20 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.8, ease: "easeOut" }}
                    >
                        <div className="mockup-wrapper">
                            <img src={deviceMockup} alt="Smartscribe on multiple devices" className="device-mockup" />
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
                    </motion.div>
                </div>
            </div>
        </section>
    );
};

export default AnyDevice;
