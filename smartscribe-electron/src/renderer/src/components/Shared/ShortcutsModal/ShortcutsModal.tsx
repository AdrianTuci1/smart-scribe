import React, { useState } from 'react';
import { X, Pencil } from 'lucide-react';
import { ShortcutRecorderModal } from '../../Settings/ShortcutRecorderModal';
import './ShortcutsModal.css';

interface ShortcutsModalProps {
    isOpen: boolean;
    onClose: () => void;
    pushToTalkKey: string;
    handsFreeModeKey: string;
    commandModeKey: string;
    onSave: (key: 'pushToTalkKey' | 'handsFreeModeKey' | 'commandModeKey', value: string) => void;
}

interface ShortcutItem {
    id: string;
    label: string;
    description: string;
    keySetting: 'pushToTalkKey' | 'handsFreeModeKey' | 'commandModeKey';
    currentValue: string;
}

export const ShortcutsModal: React.FC<ShortcutsModalProps> = ({
    isOpen,
    onClose,
    pushToTalkKey,
    handsFreeModeKey,
    commandModeKey,
    onSave
}) => {
    // State to track which shortcut is being recorded
    const [recordingItem, setRecordingItem] = useState<ShortcutItem | null>(null);

    const shortcuts: ShortcutItem[] = [
        { id: 'ptt', label: 'Push to talk', description: 'Hold to say something short', keySetting: 'pushToTalkKey', currentValue: pushToTalkKey },
        { id: 'handsfree', label: 'Hands-free mode', description: 'Press to start and stop dictation', keySetting: 'handsFreeModeKey', currentValue: handsFreeModeKey },
        { id: 'command', label: 'Command Mode', description: 'Select text and ask Flow a question', keySetting: 'commandModeKey', currentValue: commandModeKey },
    ];

    const handleStartEdit = (item: ShortcutItem) => {
        setRecordingItem(item);
    };

    const handleSaveShortcut = async (newShortcut: string) => {
        if (!recordingItem) return;

        try {
            // Call the parent's save handler
            onSave(recordingItem.keySetting, newShortcut);

            // Also invoke IPC for native listeners (Electron main process)
            await (window as any).electron.ipcRenderer.invoke('set-setting', recordingItem.keySetting, newShortcut);
        } catch (error) {
            console.error('Failed to save shortcut:', error);
        }

        setRecordingItem(null);
    };

    const handleReset = async () => {
        const defaults = {
            pushToTalkKey: 'Fn',
            handsFreeModeKey: 'Cmd+Shift+H',
            commandModeKey: 'Ctrl+Space'
        };

        try {
            // Reset all shortcuts to defaults
            onSave('pushToTalkKey', defaults.pushToTalkKey);
            onSave('handsFreeModeKey', defaults.handsFreeModeKey);
            onSave('commandModeKey', defaults.commandModeKey);

            // Invoke IPC for each setting
            for (const [key, value] of Object.entries(defaults)) {
                await (window as any).electron.ipcRenderer.invoke('set-setting', key, value);
            }
        } catch (error) {
            console.error('Failed to reset shortcuts:', error);
        }
    };

    if (!isOpen) return null;

    return (
        <>
            <div className="shortcuts-modal-overlay" onClick={onClose}>
                <div className="shortcuts-modal" onClick={e => e.stopPropagation()}>
                    <div className="shortcuts-modal-header">
                        <div className="header-text">
                            <h2>Change hotkeys</h2>
                            <p>Customize how you interact with Flow</p>
                        </div>
                        <button className="close-button" onClick={onClose}>
                            <X size={20} />
                        </button>
                    </div>

                    <div className="shortcuts-modal-content">
                        {shortcuts.map(item => (
                            <div key={item.id} className="shortcut-card">
                                <div className="shortcut-info">
                                    <h3>{item.label}</h3>
                                    <p>{item.description}</p>
                                </div>
                                <div className="shortcut-action">
                                    <div className="shortcut-input-wrapper">
                                        <div className="shortcut-value">
                                            {formatShortcut(item.currentValue)}
                                        </div>
                                        <button className="edit-shortcut-btn" onClick={() => handleStartEdit(item)}>
                                            <Pencil size={14} />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>

                    <div className="shortcuts-modal-footer">
                        <button className="reset-default-btn" onClick={handleReset}>
                            Reset to default
                        </button>
                    </div>
                </div>
            </div>

            {/* Recorder Modal */}
            <ShortcutRecorderModal
                isOpen={!!recordingItem}
                title={`Set ${recordingItem?.label || 'Shortcut'}`}
                description={`Press the key combination you want to use for ${recordingItem?.label.toLowerCase()}.`}
                initialShortcut={recordingItem?.currentValue}
                onClose={() => setRecordingItem(null)}
                onSave={handleSaveShortcut}
            />
        </>
    );
};

const formatShortcut = (shortcut: string) => {
    if (!shortcut) return 'Not set';
    // Split by + and wrap in kbd-like styling
    return shortcut.split('+').map((key, i) => (
        <span key={i} className="key-badge">{key}</span>
    ));
};
