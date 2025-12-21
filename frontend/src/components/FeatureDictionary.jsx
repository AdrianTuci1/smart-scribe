import React from 'react';
import { motion, useTransform } from 'framer-motion';

const DictionaryItem = ({ text, x }) => (
    <motion.div
        style={{ x }}
        className="dictionary-item"
    >
        <span className="dictionary-text">{text}</span>
    </motion.div>
);

const FeatureDictionary = ({ progress, entryRange }) => {
    const start = entryRange[0];
    const end = entryRange[1];

    // Staggered X translation
    const x1 = useTransform(progress, [start, end], [400, 0]);
    const x2 = useTransform(progress, [start, end], [450, 0]);
    const x3 = useTransform(progress, [start, end], [500, 0]);
    const x4 = useTransform(progress, [start, end], [550, 0]);
    const x5 = useTransform(progress, [start, end], [600, 0]);
    const x6 = useTransform(progress, [start, end], [650, 0]);
    const x7 = useTransform(progress, [start, end], [700, 0]);

    return (
        <div className="feature-visual-container">
            {/* Header */}
            <div className="feature-visual-header">
                <h3 className="feature-visual-title">Your Dictionary</h3>
                <button className="feature-add-button">
                    +
                </button>
            </div>

            {/* List */}
            <div className="dictionary-list">
                <DictionaryItem text="Robyn" x={x1} />
                <DictionaryItem text="Viktor" x={x2} />
                <DictionaryItem text="SaaS" x={x3} />
                <DictionaryItem text="Caltrain" x={x4} />
                <DictionaryItem text="Mackey" x={x5} />
                <DictionaryItem text="Nguyen" x={x6} />
                <div className="opacity-50" style={{ opacity: 0.5 }}>
                    <DictionaryItem text="Leona" x={x7} />
                </div>
            </div>
            <div className="dictionary-fade-overlay"></div>
        </div>
    );
};

export default FeatureDictionary;
