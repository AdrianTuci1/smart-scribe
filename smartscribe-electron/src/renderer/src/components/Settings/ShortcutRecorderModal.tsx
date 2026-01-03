import React, { useEffect, useState } from 'react';
import { X } from 'lucide-react';
import './ShortcutRecorderModal.css';

interface ShortcutRecorderModalProps {
    isOpen: boolean;
    title: string;
    description?: string;
    initialShortcut?: string;
    onClose: () => void;
    onSave: (shortcut: string) => void;
}

export const ShortcutRecorderModal: React.FC<ShortcutRecorderModalProps> = ({
    isOpen,
    title,
    description,
    initialShortcut = '',
    onClose,
    onSave
}) => {
    const [currentShortcut, setCurrentShortcut] = useState<string>(initialShortcut || 'Press a key...');
    const [isRecording, setIsRecording] = useState(false);

    // Reset state when opened
    useEffect(() => {
        const electron = (window as any).electron;
        if (isOpen) {
            setCurrentShortcut(initialShortcut || '');
            setIsRecording(true);
            electron?.ipcRenderer.send('set-shortcut-recording-state', true);
        } else {
            setIsRecording(false);
            electron?.ipcRenderer.send('set-shortcut-recording-state', false);
        }

        return () => {
            // Ensure we reset when unmounting if it was open
            if (isOpen) {
                electron?.ipcRenderer.send('set-shortcut-recording-state', false);
            }
        };
    }, [isOpen, initialShortcut]);

    useEffect(() => {
        if (!isOpen) return;

        const electron = (window as any).electron;
        if (!electron || !electron.ipcRenderer) return;

        const handleKeyEvent = (data: any) => {
            if (!isRecording) {
                return;
            }

            const { type, modifiers, keyCode, chars } = data;

            // Only update on keydown or flagsChanged (for modifiers)
            if (type === 'keyup') return;

            // Avoid capturing just 'Escape' to allow closing via Esc implicitly 
            if (keyCode === 53 && modifiers.length === 0) {
                return;
            }

            let newShortcut = '';

            // Sort modifiers for consistency: Ctrl, Alt, Shift, Cmd, Fn
            // This order is arbitrary but good for stability
            const priority: Record<string, number> = { 'Control': 0, 'Alt': 1, 'Shift': 2, 'Command': 3, 'Cmd': 3, 'Fn': 4 };
            const parts = [...new Set(modifiers)].sort((a: any, b: any) => {
                return (priority[a] ?? 99) - (priority[b] ?? 99);
            });

            let shouldStopRecording = false;

            // 1. Modifier only (e.g. Fn, Cmd)
            if (type === 'flagsChanged') {
                if (parts.length > 0) {
                    newShortcut = parts.join('+');
                }
            }
            // 2. Key + Modifiers
            else if (type === 'keydown') {
                let keyName = chars;
                if (!keyName && keyCode === 49) keyName = 'Space';

                if (keyName) {
                    newShortcut = [...parts, keyName].join('+');
                    shouldStopRecording = true; // Auto-stop on standard key press
                } else if (parts.length > 0) {
                    newShortcut = parts.join('+');
                    // Do not stop if only modifiers found in keydown (rare fallback)
                }
            }

            if (newShortcut) {
                console.log('Detected shortcut:', newShortcut);
                setCurrentShortcut(newShortcut);

                if (shouldStopRecording) {
                    setIsRecording(false);
                }
            } else {
                // If result is empty (e.g. keys released), do NOT update. 
                // This latches the last valid shortcut (e.g. "Fn") so it doesn't disappear on release.
            }
        };

        const removeListener = electron.ipcRenderer.on('global-key-event', handleKeyEvent);

        // Also add local listener for Escape to close
        const handleLocalKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'Escape') {
                onClose();
            }
        };
        window.addEventListener('keydown', handleLocalKeyDown);

        return () => {
            removeListener();
            window.removeEventListener('keydown', handleLocalKeyDown);
        };
    }, [isOpen, isRecording, onClose]);

    if (!isOpen) return null;

    return (
        <div className="shortcut-modal-overlay" onClick={onClose}>
            <div className="shortcut-modal-content" onClick={(e) => e.stopPropagation()}>
                <h3 className="shortcut-modal-title">{title}</h3>
                {description && <p className="shortcut-modal-subtitle">{description}</p>}

                <div className={`shortcut-display-area ${isRecording ? 'recording' : ''}`}>
                    {currentShortcut ? (
                        <div className="shortcut-key-combo">
                            {currentShortcut.split('+').map((key, index) => (
                                <div key={index} className={`shortcut-key-cap ${isRecording ? 'purple' : ''}`}>
                                    {key}
                                </div>
                            ))}
                        </div>
                    ) : (
                        <span style={{ color: '#666' }}>Type a shortcut...</span>
                    )}
                </div>

                <div className="shortcut-modal-actions">
                    <button className="shortcut-modal-btn cancel" onClick={onClose}>
                        Cancel
                    </button>
                    <button
                        className="shortcut-modal-btn save"
                        onClick={() => onSave(currentShortcut)}
                        disabled={!currentShortcut || currentShortcut === 'Press a key...'}
                    >
                        Save Shortcut
                    </button>
                </div>
            </div>
        </div>
    );
};
