import React, { useState, useEffect } from 'react';
import { SettingsTabProps } from './types';
import { ToggleSwitch } from './ToggleSwitch';
import { X } from 'lucide-react';

export const GeneralSettings: React.FC<SettingsTabProps> = ({ settings, onSettingChange }) => {
    const [capturingTarget, setCapturingTarget] = useState<string | null>(null);

    useEffect(() => {
        const handleGlobalKey = (_event: any, keyData: any) => {
            if (!capturingTarget) return;

            console.log('Global Key:', keyData);

            const { type, modifiers, keyCode, chars } = keyData;

            // We only care about keydown or flagsChanged
            if (type === 'keyup') return;

            // Check for Escape to cancel
            if (keyCode === 53) { // 53 is Escape
                setCapturingTarget(null);
                return;
            }

            let parts = [...modifiers];

            // Handle modifiers-only (Fn, Cmd, etc.)
            if (type === 'flagsChanged') {
                if (parts.length > 0) {
                    const shortcut = parts.join('+');
                    onSettingChange(capturingTarget as any, shortcut);
                    setCapturingTarget(null);
                }
                return;
            }

            // Handle KeyDown with chars
            if (type === 'keydown') {
                let keyName = chars;
                // Fallback or specific overrides if needed
                if (!keyName && keyCode === 49) keyName = 'Space';

                if (keyName) {
                    // Combine modifiers + key
                    const shortcut = [...parts, keyName].join('+');
                    onSettingChange(capturingTarget as any, shortcut);
                    setCapturingTarget(null);
                }
            }
        };

        if ((window as any).electron && (window as any).electron.ipcRenderer) {
            const removeListener = (window as any).electron.ipcRenderer.on('global-key-event', handleGlobalKey);
            return () => {
                if (removeListener) removeListener();
            };
        }
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
                            {capturingTarget === 'pushToTalkKey' ? (
                                <span className="recording-text">
                                    Press keys... (Esc to cancel) <X className="inline-icon" size={14} onClick={(e: React.MouseEvent) => { e.stopPropagation(); setCapturingTarget(null); }} />
                                </span>
                            ) : (
                                <span className="key-combo">{settings.pushToTalkKey}</span>
                            )}
                        </button>
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Hands-Free Mode</span>
                        <button
                            className={`shortcut-button ${capturingTarget === 'handsFreeModeKey' ? 'recording' : ''}`}
                            onClick={() => setCapturingTarget('handsFreeModeKey')}
                        >
                            {capturingTarget === 'handsFreeModeKey' ? (
                                <span className="recording-text">
                                    Press keys... (Esc to cancel) <X className="inline-icon" size={14} onClick={(e: React.MouseEvent) => { e.stopPropagation(); setCapturingTarget(null); }} />
                                </span>
                            ) : (
                                <span className="key-combo">{settings.handsFreeModeKey}</span>
                            )}
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
