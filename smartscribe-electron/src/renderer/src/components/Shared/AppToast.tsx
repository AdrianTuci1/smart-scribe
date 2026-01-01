import React, { useEffect, useState } from 'react';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';
import './AppToast.css';
import clsx from 'clsx';

export type ToastType = 'success' | 'error' | 'info';

interface AppToastProps {
    message: string | null;
    type?: ToastType;
    duration?: number;
    onClose: () => void;
}

export const AppToast: React.FC<AppToastProps> = ({ message, type = 'success', duration = 3000, onClose }) => {
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        if (message) {
            setIsVisible(true);
            const timer = setTimeout(() => {
                setIsVisible(false);
                setTimeout(onClose, 300); // Wait for fade out
            }, duration);
            return () => clearTimeout(timer);
        }
    }, [message, duration, onClose]);

    if (!message && !isVisible) return null;

    const Icon = type === 'success' ? CheckCircle2 : type === 'error' ? AlertCircle : Info;

    return (
        <div className={clsx("app-toast", type, isVisible ? "show" : "hide")}>
            <Icon size={20} className="toast-icon" />
            <span className="toast-message">{message}</span>
            <button className="toast-close" onClick={() => setIsVisible(false)}>
                <X size={16} />
            </button>
        </div>
    );
};
