import React from 'react';
import { motion, useTransform } from 'framer-motion';

const SnippetItem = ({ text, delay, x, customStyle }) => (
    <motion.div
        style={{ x, opacity: 1, ...customStyle }}
        className="snippet-item"
    >
        <span className="snippet-text">{text}</span>
    </motion.div>
);

const FeatureSnippets = ({ progress, entryRange }) => {
    // Map progress to entry animation
    // When progress is at entryRange[0], items are offscreen
    // When progress is at entryRange[1], items are in place

    // We'll create a staggered effect by using slightly different ranges or offsets
    // But strictly using useTransform with the single progress value:

    const start = entryRange[0];
    const end = entryRange[1];

    // First item (Calendar) slides in from right
    const x1 = useTransform(progress, [start, end], [400, 0]);

    // List items slide down from under the Calendar item
    const y2 = useTransform(progress, [start, end], [-40, 0]);
    const y3 = useTransform(progress, [start, end], [-80, 0]);
    const y4 = useTransform(progress, [start, end], [-120, 0]);
    const y5 = useTransform(progress, [start, end], [-160, 0]);

    // Message specialized animation
    // Starts with negative Y (moved up behind the item) and opaque
    const yMessage = useTransform(progress, [start, end], [-60, 0]);
    const opacityMessage = useTransform(progress, [start, end], [1, 1]); // Keep opaque for mask effect

    // Opacity fade in for list items
    const opacity2 = useTransform(progress, [start, end], [0, 1]);
    const opacity3 = useTransform(progress, [start, end], [0, 1]);
    const opacity4 = useTransform(progress, [start, end], [0, 1]);
    const opacity5 = useTransform(progress, [start, end], [0, 1]);

    return (
        <div className="feature-visual-container">
            {/* Header */}
            <div className="feature-visual-header">
                <h3 className="feature-visual-title">Your Snippets</h3>
                <button className="feature-add-button">
                    +
                </button>
            </div>

            {/* List */}
            <div className="feature-list-container">
                <SnippetItem text="Calendar" x={x1} customStyle={{ zIndex: 10, position: 'relative' }} />

                {/* Indented Message - Slides down from under Calendar */}
                <motion.div
                    style={{ opacity: opacityMessage, x: x1, y: yMessage, zIndex: 1, position: 'relative' }}
                    className="snippet-indented-message"
                >
                    You can book a 30-minute call with me here: calendly.com/wisprflow
                </motion.div>

                <SnippetItem text="Hours" x={0} customStyle={{ y: y2, opacity: opacity2 }} />
                <SnippetItem text="Support intro" x={0} customStyle={{ y: y3, opacity: opacity3 }} />
                <SnippetItem text="FAQ" x={0} customStyle={{ y: y4, opacity: opacity4 }} />
                <div className="opacity-50" style={{ opacity: 0.5 }}>
                    <SnippetItem text="Careers link" x={0} customStyle={{ y: y5, opacity: opacity5 }} />
                </div>
            </div>
        </div>
    );
};

export default FeatureSnippets;
