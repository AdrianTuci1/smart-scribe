import React from 'react';
import './DataEntryItem.css';
import clsx from 'clsx';

interface DataEntryItemProps {
    children: React.ReactNode;
    actions?: React.ReactNode;
    onClick?: () => void;
    className?: string;
}

export const DataEntryItem: React.FC<DataEntryItemProps> = ({ children, actions, onClick, className }) => {
    return (
        <div
            className={clsx("data-entry-item", className)}
            onClick={onClick}
        >
            <div className="data-entry-content">
                {children}
            </div>
            {actions && (
                <div className="data-entry-actions" onClick={(e) => e.stopPropagation()}>
                    {actions}
                </div>
            )}
        </div>
    );
};
