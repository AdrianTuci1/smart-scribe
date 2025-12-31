import React from 'react';
import './FloatingWaveform.css';

interface WarningToastProps {
    visible: boolean;
    onClose: () => void;
}

export const WarningToast: React.FC<WarningToastProps> = ({ visible, onClose }) => {
    if (!visible) return null;

    return (
        <div className="warning-toast">
            <div className="warning-header">
                <div className="warning-title">
                    <svg className="warning-icon" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z" />
                    </svg>
                    Don't tap. Hold down your shortcut.
                </div>
                <button className="warning-close-btn" onClick={onClose}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 17.59 13.41 12z" />
                    </svg>
                </button>
            </div>
            <div className="warning-body">
                Hold down your shortcut while speaking, and release to see your text.
            </div>
        </div>
    );
};
