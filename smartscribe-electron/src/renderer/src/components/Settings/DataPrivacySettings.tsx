import React from 'react';
import { RotateCw, Trash, FileText, ChevronRight } from 'lucide-react';
import { SettingsTabProps } from './types';
import { ToggleSwitch } from './ToggleSwitch';

export const DataPrivacySettings: React.FC<SettingsTabProps> = ({ settings, onSettingChange }) => {
    return (
        <>
            <div className="settings-section">
                <h3 className="settings-section-title">Privacy Settings</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Privacy Mode</span>
                        <ToggleSwitch checked={settings.privacyMode} onChange={(c) => onSettingChange('privacyMode', c)} />
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Context Awareness</span>
                        <ToggleSwitch checked={settings.contextAwareness} onChange={(c) => onSettingChange('contextAwareness', c)} />
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Data Management</h3>
                <div className="settings-card">
                    <button className="settings-action-button">
                        <RotateCw size={18} />
                        <span>Hard Refresh All Notes</span>
                    </button>
                    <button className="settings-action-button danger">
                        <Trash size={18} />
                        <span>Delete History of All Activity</span>
                    </button>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">HIPAA Compliance</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Enable HIPAA</span>
                        <ToggleSwitch checked={settings.hipaaEnabled} onChange={(c) => onSettingChange('hipaaEnabled', c)} />
                    </div>
                    {settings.hipaaEnabled && (
                        <button className="settings-action-button">
                            <FileText size={18} />
                            <span>View and Accept HIPAA Agreement</span>
                            <ChevronRight size={18} style={{ marginLeft: 'auto' }} />
                        </button>
                    )}
                </div>
            </div>
        </>
    );
};
