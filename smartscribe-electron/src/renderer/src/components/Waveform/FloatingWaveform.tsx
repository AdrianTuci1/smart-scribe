import React, { useState } from 'react';
import { X, Mic, Square } from 'lucide-react';
import './FloatingWaveform.css';
import clsx from 'clsx';

type ChipState = 'idle' | 'hover' | 'recording';

export const FloatingWaveform: React.FC = () => {
    const [state, setState] = useState<ChipState>('idle');
    const [isHovering, setIsHovering] = useState(false);

    const handleMouseEnter = () => {
        setIsHovering(true);
        if (state === 'idle') setState('hover');
    };

    const handleMouseLeave = () => {
        setIsHovering(false);
        if (state === 'hover') setState('idle');
    };

    const toggleRecording = () => {
        if (state === 'recording') {
            setState('idle');
            // Logic to stop recording
        } else {
            setState('recording');
            // Logic to start recording
        }
    };

    return (
        <div className="floating-waveform-container">
            <div
                className={clsx("waveform-chip", state)}
                onMouseEnter={handleMouseEnter}
                onMouseLeave={handleMouseLeave}
                onClick={() => state !== 'recording' && toggleRecording()}
            >
                {state === 'recording' && (
                    <button className="control-btn close-btn" onClick={(e) => { e.stopPropagation(); toggleRecording(); }}>
                        <X size={10} strokeWidth={4} />
                    </button>
                )}

                <div className="waveform-bars">
                    {[1, 2, 3, 4, 5].map((i) => (
                        <div key={i} className="bar"></div>
                    ))}
                </div>

                {state === 'recording' && (
                    <button className="control-btn stop-btn" onClick={(e) => { e.stopPropagation(); toggleRecording(); }}>
                        <Square size={8} fill="currentColor" />
                    </button>
                )}
            </div>
        </div>
    );
};
