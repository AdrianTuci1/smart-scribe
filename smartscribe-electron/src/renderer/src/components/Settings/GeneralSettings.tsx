import React, { useState, useEffect } from 'react';
import { SettingsTabProps } from './types';
import { ToggleSwitch } from './ToggleSwitch';

export const GeneralSettings: React.FC<SettingsTabProps> = ({ settings, onSettingChange }) => {
    const [capturingTarget, setCapturingTarget] = useState<string | null>(null);

    useEffect(() => {
        if (!capturingTarget) return;

        const handler = (e: KeyboardEvent) => {
            e.preventDefault();
            e.stopPropagation();

            const modifiers: string[] = [];
            if (e.metaKey) modifiers.push('Cmd');
            if (e.ctrlKey) modifiers.push('Ctrl');
            if (e.altKey) modifiers.push('Alt');
            if (e.shiftKey) modifiers.push('Shift');

            if (['Meta', 'Control', 'Alt', 'Shift'].includes(e.key)) return;

            let key = e.key.toUpperCase();
            if (e.code === 'Space') key = 'Space';

            const shortcut = [...modifiers, key].join('+');

            onSettingChange(capturingTarget as any, shortcut);
            setCapturingTarget(null);
        };

        window.addEventListener('keydown', handler);
        return () => window.removeEventListener('keydown', handler);
    }, [capturingTarget, onSettingChange]);

    return (
        <>
            <div className="settings-section">
                <h3 className="settings-section-title">Keyboard Shortcuts</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Push to Talk</span>
                        <button
                            className={`shortcut-button ${capturingTarget === 'pushToTalkKey' ? 'recording' : ''}`}
                            onClick={() => setCapturingTarget('pushToTalkKey')}
                        >
                            {capturingTarget === 'pushToTalkKey' ? 'Recording...' : settings.pushToTalkKey}
                        </button>
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Hands-Free Mode</span>
                        <button
                            className={`shortcut-button ${capturingTarget === 'handsFreeModeKey' ? 'recording' : ''}`}
                            onClick={() => setCapturingTarget('handsFreeModeKey')}
                        >
                            {capturingTarget === 'handsFreeModeKey' ? 'Recording...' : settings.handsFreeModeKey}
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
