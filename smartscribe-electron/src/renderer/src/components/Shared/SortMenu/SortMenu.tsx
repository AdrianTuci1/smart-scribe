import React, { useEffect, useRef } from 'react';
import clsx from 'clsx';
import './SortMenu.css';

interface SortMenuProps {
    isOpen: boolean;
    onClose: () => void;
    sortOrder: string;
    onSortChange: (order: string) => void;
    buttonRef: React.RefObject<HTMLButtonElement | null>;
}

const SORT_OPTIONS = [
    { id: 'newest', label: 'Newest' },
    { id: 'oldest', label: 'Oldest' },
    { id: 'alphabetical', label: 'Alphabetical' },
];

export const SortMenu: React.FC<SortMenuProps> = ({
    isOpen,
    onClose,
    sortOrder,
    onSortChange,
    buttonRef
}) => {
    const menuRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (!isOpen || !buttonRef.current || !menuRef.current) return;

        // Position the menu relative to the button
        const button = buttonRef.current;
        const menu = menuRef.current;
        const buttonRect = button.getBoundingClientRect();

        // Position below the button, aligned to the right
        menu.style.top = `${buttonRect.bottom + 8}px`;
        menu.style.left = `${buttonRect.right - menu.offsetWidth}px`;
    }, [isOpen, buttonRef]);

    if (!isOpen) return null;

    return (
        <>
            <div className="sort-menu-overlay" onClick={onClose} />
            <div ref={menuRef} className="sort-menu-modal">
                {SORT_OPTIONS.map(option => (
                    <button
                        key={option.id}
                        className={clsx(
                            "sort-menu-item",
                            sortOrder === option.id && "active"
                        )}
                        onClick={() => {
                            onSortChange(option.id);
                            onClose();
                        }}
                    >
                        {option.label}
                    </button>
                ))}
            </div>
        </>
    );
};
