import React, { useState, useEffect } from 'react';
import { SettingsTabProps } from './types';
import { ToggleSwitch } from './ToggleSwitch';
import { X } from 'lucide-react';
import { ShortcutRecorderModal } from './ShortcutRecorderModal';

export const GeneralSettings: React.FC<SettingsTabProps> = ({ settings, onSettingChange }) => {
    // Modal state
    const [recordingKey, setRecordingKey] = useState<keyof typeof settings | null>(null);

    const handleSaveShortcut = (newShortcut: string) => {
        if (recordingKey) {
            onSettingChange(recordingKey, newShortcut);
            setRecordingKey(null);
        }
    };

    return (
        <>
            <ShortcutRecorderModal
                isOpen={!!recordingKey}
                title={recordingKey === 'pushToTalkKey' ? 'Set Push to Talk Shortcut' : 'Set Hands-Free Shortcut'}
                description="Press the key combination you want to use. You can use single keys (like Fn) or combinations (like Cmd+Shift+P)."
                initialShortcut={recordingKey ? (settings[recordingKey] as string) : ''}
                onClose={() => setRecordingKey(null)}
                onSave={handleSaveShortcut}
            />

            <div className="settings-section">
                <h3 className="settings-section-title">Keyboard Shortcuts</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Push to Talk</span>
                        <button
                            className="shortcut-button"
                            onClick={() => setRecordingKey('pushToTalkKey')}
                        >
                            <span className="key-combo">{settings.pushToTalkKey || 'Click to set'}</span>
                        </button>
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Hands-Free Mode</span>
                        <button
                            className="shortcut-button"
                            onClick={() => setRecordingKey('handsFreeModeKey')}
                        >
                            <span className="key-combo">{settings.handsFreeModeKey || 'Click to set'}</span>
                        </button>
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Command Mode</span>
                        <ToggleSwitch
                            checked={settings.commandModeEnabled}
                            onChange={(checked) => onSettingChange('commandModeEnabled', checked)}
                        />
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Paste Last Transcript</span>
                        <ToggleSwitch
                            checked={settings.pasteLastTranscriptEnabled}
                            onChange={(checked) => onSettingChange('pasteLastTranscriptEnabled', checked)}
                        />
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Microphone</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Input Device</span>
                        <select
                            className="settings-select"
                            value={settings.selectedMicrophone}
                            onChange={(e) => onSettingChange('selectedMicrophone', e.target.value)}
                        >
                            <option>Auto Detect</option>
                            <option>Built-in Microphone</option>
                            <option>External Microphone 1</option>
                        </select>
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Language</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Transcription Language</span>
                        <select
                            className="settings-select"
                            value={settings.selectedLanguage}
                            onChange={(e) => onSettingChange('selectedLanguage', e.target.value)}
                        >
                            <option>English (US)</option>
                            <option>English (UK)</option>
                            <option>Spanish</option>
                            <option>French</option>
                            <option>German</option>
                            <option>Romanian</option>
                        </select>
                    </div>
                </div>
            </div>
        </>
    );
};
