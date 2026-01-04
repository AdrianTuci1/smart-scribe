import React from 'react';
import './FloatingWaveform.css';

interface ProcessingToastProps {
    visible: boolean;
    onClose: () => void;
}

export const ProcessingToast: React.FC<ProcessingToastProps> = ({ visible, onClose }) => {
    if (!visible) return null;

    return (
        <div className="warning-toast">
            <div className="warning-header">
                <div className="warning-title">
                    <svg className="warning-icon" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z" />
                    </svg>
                    Processing...
                </div>
                <button className="warning-close-btn" onClick={onClose}>
                    x
                </button>
            </div>
            <div className="warning-body">
                It takes longer than usual, your transcript will be ready soon
            </div>
        </div>
    );
};
