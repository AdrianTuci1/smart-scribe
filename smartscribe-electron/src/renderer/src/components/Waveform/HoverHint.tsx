import React from 'react';
import './FloatingWaveform.css';

interface HoverHintProps {
    shortcutKey: string;
}

export const HoverHint: React.FC<HoverHintProps> = ({ shortcutKey }) => {
    return (
        <div className="hover-hint">
            Click or hold <span className="fn-key">{shortcutKey}</span> to start dictating
        </div>
    );
};
