import React from 'react';
import { SettingsTabProps } from './types';
import { ToggleSwitch } from './ToggleSwitch';

export const VibeCodingSettings: React.FC<SettingsTabProps> = ({ settings, onSettingChange }) => {
    return (
        <>
            <div className="settings-section">
                <h3 className="settings-section-title">Vibe Coding Features</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <div className="row-label-wrapper">
                            <span className="row-label">Variable Recognition</span>
                            <span className="row-subtitle">Automatically recognize and highlight variables in your code</span>
                        </div>
                        <ToggleSwitch checked={settings.variableRecognition} onChange={(c) => onSettingChange('variableRecognition', c)} />
                    </div>
                    <div className="settings-row">
                        <div className="row-label-wrapper">
                            <span className="row-label">File Tagging in Chat</span>
                            <span className="row-subtitle">Automatically tag files when mentioned in chat for better organization</span>
                        </div>
                        <ToggleSwitch checked={settings.fileTaggingInChat} onChange={(c) => onSettingChange('fileTaggingInChat', c)} />
                    </div>
                </div>
            </div>
        </>
    );
};
