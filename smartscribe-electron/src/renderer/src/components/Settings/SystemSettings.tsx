import React from 'react';
import { RotateCcw } from 'lucide-react';
import { SettingsTabProps } from './types';
import { ToggleSwitch } from './ToggleSwitch';

export const SystemSettings: React.FC<SettingsTabProps> = ({ settings, onSettingChange }) => {
    return (
        <>
            <div className="settings-section">
                <h3 className="settings-section-title">App Settings</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Launch App at Login</span>
                        <ToggleSwitch checked={settings.launchAtLogin} onChange={(c) => onSettingChange('launchAtLogin', c)} />
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Show Flow Bar at All Times</span>
                        <ToggleSwitch checked={settings.showFlowBarAlways} onChange={(c) => onSettingChange('showFlowBarAlways', c)} />
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Show in Dock</span>
                        <ToggleSwitch checked={settings.showInDock} onChange={(c) => onSettingChange('showInDock', c)} />
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Sounds</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Dictation Sound Effect</span>
                        <ToggleSwitch checked={settings.dictationSoundEffect} onChange={(c) => onSettingChange('dictationSoundEffect', c)} />
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Mute Music While Dictating</span>
                        <ToggleSwitch checked={settings.muteMusicWhileDictating} onChange={(c) => onSettingChange('muteMusicWhileDictating', c)} />
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Extras</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label">Auto Add to Directory</span>
                        <ToggleSwitch checked={settings.autoAddToDirectory} onChange={(c) => onSettingChange('autoAddToDirectory', c)} />
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Smart Formatting</span>
                        <ToggleSwitch checked={settings.smartFormatting} onChange={(c) => onSettingChange('smartFormatting', c)} />
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Email Auto Signature</span>
                        <ToggleSwitch checked={settings.emailAutoSignature} onChange={(c) => onSettingChange('emailAutoSignature', c)} />
                    </div>
                    <div className="settings-row">
                        <span className="row-label">Creator Mode</span>
                        <ToggleSwitch checked={settings.creatorMode} onChange={(c) => onSettingChange('creatorMode', c)} />
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Data</h3>
                <div className="settings-card">
                    <button className="settings-action-button danger">
                        <RotateCcw size={18} />
                        <span>Reset App</span>
                    </button>
                </div>
            </div>
        </>
    );
};
