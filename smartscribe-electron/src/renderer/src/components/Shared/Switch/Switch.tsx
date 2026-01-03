import React from 'react';
import clsx from 'clsx';
import './Switch.css';

interface SwitchProps {
    label: string;
    checked: boolean;
    onChange: (checked: boolean) => void;
    disabled?: boolean;
}

export const Switch: React.FC<SwitchProps> = ({ label, checked, onChange, disabled = false }) => {
    return (
        <div className="switch-container">
            <span className="switch-label">{label}</span>
            <button
                type="button"
                role="switch"
                aria-checked={checked}
                disabled={disabled}
                className={clsx(
                    'switch-track',
                    checked && 'checked',
                    disabled && 'disabled'
                )}
                onClick={() => !disabled && onChange(!checked)}
            >
                <span className={clsx('switch-thumb', checked && 'checked')} />
            </button>
        </div>
    );
};
