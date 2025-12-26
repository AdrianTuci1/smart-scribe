import React from 'react';
import { SettingsTabProps } from './types';
import { ToggleSwitch } from './ToggleSwitch';

export const ExperimentalSettings: React.FC<SettingsTabProps> = ({ settings, onSettingChange }) => {
    return (
        <>
            <div className="warning-banner">
                <div className="warning-icon">⚠️</div>
                <div className="warning-text">These features are experimental and may cause instability. Use with caution.</div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Experimental Features</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <div className="row-label-wrapper">
                            <span className="row-label">Command Mode - Enable Advanced Voice Commands</span>
                            <span className="row-subtitle">Enable advanced voice commands for more complex operations and automation</span>
                        </div>
                        <ToggleSwitch checked={settings.advancedVoiceCommands} onChange={(c) => onSettingChange('advancedVoiceCommands', c)} />
                    </div>
                </div>
            </div>
        </>
    );
};
