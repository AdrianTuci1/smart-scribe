
import React, { useState, useRef, useEffect } from 'react';
import { Transcript } from '../../../types';
import { Copy, Flag, Trash2, RotateCcw, MoreVertical, Download, RefreshCw, Undo2 } from 'lucide-react';
import clsx from 'clsx';
import { format } from 'date-fns';
import './TranscriptRow.css';

interface TranscriptRowProps {
    transcript: Transcript;
    showTime: boolean;
    isLast?: boolean;
    onCopy: (t: Transcript) => void;
    onFlag: (t: Transcript) => void;
    onUndoAIEdit: (t: Transcript) => void;
    onRetry: (t: Transcript) => void;
    onDelete: (t: Transcript) => void;
    onDownloadAudio: (t: Transcript) => void;
}

export const TranscriptRow: React.FC<TranscriptRowProps> = ({
    transcript,
    showTime,
    isLast,
    onCopy,
    onFlag,
    onUndoAIEdit,
    onRetry,
    onDelete,
    onDownloadAudio
}) => {
    const [isHovered, setIsHovered] = useState(false);
    const [showMenu, setShowMenu] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
                setShowMenu(false);
            }
        };

        if (showMenu) {
            document.addEventListener('mousedown', handleClickOutside);
        }
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [showMenu]);

    return (
        <div
            className={clsx(
                "transcript-row group",
                !isLast && "is-last", // Negation mistake in class logic in my head vs file? 
                // Wait, !isLast means it HAS a bottom border usually. In CSS I wrote :not(.is-last) has border.
                // So if it IS last, I want it to BE .is-last class. 
                isLast && "is-last",
                (isHovered || showMenu) && "active"
            )}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
        >
            {/* Time Column */}
            <div className="time-col">
                <span className={clsx(
                    "timestamp",
                    !showTime && "hidden"
                )}>
                    {format(new Date(transcript.timestamp), 'hh:mm a')}
                </span>
            </div>

            {/* Content Column */}
            <div className="content-col">
                <p className="transcript-text">
                    {transcript.text}
                </p>

                {/* Actions */}
                <div className="actions-container">
                    <button
                        onClick={() => onCopy(transcript)}
                        className="action-btn"
                        title="Copy text"
                    >
                        <Copy size={16} />
                    </button>

                    <button
                        onClick={() => onFlag(transcript)}
                        className={clsx(
                            "action-btn",
                            transcript.isFlagged && "flagged"
                        )}
                        title={transcript.isFlagged ? "Remove flag" : "Flag transcript"}
                    >
                        <Flag size={16} fill={transcript.isFlagged ? "currentColor" : "none"} />
                    </button>

                    {/* Simplified More Menu */}
                    <div className="menu-container" ref={menuRef}>
                        <button
                            onClick={() => setShowMenu(!showMenu)}
                            className={clsx(
                                "action-btn",
                                showMenu && "menu-open"
                            )}
                        >
                            <MoreVertical size={16} />
                        </button>

                        {showMenu && (
                            <div className="dropdown-menu">
                                <MenuItem onClick={() => onUndoAIEdit(transcript)} icon={<Undo2 size={14} />} label="Undo AI edit" />
                                <MenuItem onClick={() => onRetry(transcript)} icon={<RefreshCw size={14} />} label="Retry transcript" />
                                <div className="menu-divider" />
                                <MenuItem onClick={() => onDelete(transcript)} icon={<Trash2 size={14} />} label="Delete transcript" className="danger" />
                                <div className="menu-divider" />
                                <MenuItem onClick={() => onDownloadAudio(transcript)} icon={<Download size={14} />} label="Download audio" />
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

const MenuItem: React.FC<{
    onClick: () => void;
    icon: React.ReactNode;
    label: string;
    className?: string; // e.g. "danger"
}> = ({ onClick, icon, label, className }) => (
    <button
        onClick={onClick}
        className={clsx(
            "menu-item",
            className
        )}
    >
        <span className="menu-icon">{icon}</span>
        {label}
    </button>
);
