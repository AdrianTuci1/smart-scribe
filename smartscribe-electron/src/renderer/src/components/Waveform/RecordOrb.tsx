import React from 'react';
import './FloatingWaveform.css';

interface RecordOrbProps {
    isRecording: boolean;
    onClick: () => void;
    onContextMenu: (e: React.MouseEvent) => void;
}

export const RecordOrb: React.FC<RecordOrbProps> = ({ isRecording, onClick, onContextMenu }) => {
    return (
        <button
            className={`record-orb-btn ${isRecording ? 'recording' : ''}`}
            onClick={onClick}
            onContextMenu={onContextMenu}
        >
            <div className="btn-icon-wrapper">
                {/* Mic Icon */}
                <svg className="btn-icon icon-mic" viewBox="0 0 24 24">
                    <path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z" />
                    <path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z" />
                </svg>

                {/* Stop Icon */}
                <svg className="btn-icon icon-stop" viewBox="0 0 24 24">
                    <rect x="6" y="6" width="12" height="12" rx="2" />
                </svg>
            </div>
        </button>
    );
};
