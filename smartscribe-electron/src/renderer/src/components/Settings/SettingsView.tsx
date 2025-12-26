import React, { useState, useEffect } from 'react';
import {
    X, Keyboard, Monitor, BrainCircuit, FlaskConical,
    User, Users, CreditCard, Shield
} from 'lucide-react';
import './SettingsView.css';
import { SettingsCategory, UserSettings, defaultSettings } from './types';
import { GeneralSettings } from './GeneralSettings';
import { SystemSettings } from './SystemSettings';
import { VibeCodingSettings } from './VibeCodingSettings';
import { ExperimentalSettings } from './ExperimentalSettings';
import { AccountSettings } from './AccountSettings';
import { TeamSettings } from './TeamSettings';
import { PlansBillingSettings } from './PlansBillingSettings';
import { DataPrivacySettings } from './DataPrivacySettings';

interface SettingsViewProps {
    onClose: () => void;
    initialTab?: SettingsCategory;
}

export const SettingsView: React.FC<SettingsViewProps> = ({ onClose, initialTab = 'general' }) => {
    const [selectedCategory, setSelectedCategory] = useState<SettingsCategory>(initialTab);
    const [settings, setSettings] = useState<UserSettings>(defaultSettings);

    // Initial load of settings from backend
    useEffect(() => {
        const loadSettings = async () => {
            try {
                const savedSettings = await window.electron.ipcRenderer.getAllSettings();
                if (savedSettings) {
                    setSettings(prev => ({ ...prev, ...savedSettings }));
                }
            } catch (err) {
                console.error("Failed to load settings:", err);
            }
        };
        loadSettings();
    }, []);

    const handleSettingChange = (key: keyof UserSettings, value: any) => {
        const newSettings = { ...settings, [key]: value };
        setSettings(newSettings);
        window.electron.ipcRenderer.setSetting(key, value);
    };

    const categories: { id: SettingsCategory; label: string; icon: React.ElementType }[] = [
        { id: 'general', label: 'General', icon: Keyboard },
        { id: 'system', label: 'System', icon: Monitor },
        { id: 'vibeCoding', label: 'Vibe Coding', icon: BrainCircuit },
        { id: 'experimental', label: 'Experimental', icon: FlaskConical },
        { id: 'account', label: 'Account', icon: User },
        { id: 'team', label: 'Team', icon: Users },
        { id: 'plansBilling', label: 'Plans & Billing', icon: CreditCard },
        { id: 'dataPrivacy', label: 'Data & Privacy', icon: Shield },
    ];

    const renderContent = () => {
        const tabProps = { settings, onSettingChange: handleSettingChange };

        switch (selectedCategory) {
            case 'general': return <GeneralSettings {...tabProps} />;
            case 'system': return <SystemSettings {...tabProps} />;
            case 'vibeCoding': return <VibeCodingSettings {...tabProps} />;
            case 'experimental': return <ExperimentalSettings {...tabProps} />;
            case 'account': return <AccountSettings {...tabProps} />;
            case 'team': return <TeamSettings {...tabProps} />;
            case 'plansBilling': return <PlansBillingSettings {...tabProps} />;
            case 'dataPrivacy': return <DataPrivacySettings {...tabProps} />;
            default: return <div className="p-4">Coming Soon...</div>;
        }
    };

    return (
        <div className="settings-modal-overlay" onClick={onClose}>
            <div className="settings-modal-container" onClick={e => e.stopPropagation()}>
                {/* Sidebar */}
                <div className="settings-sidebar">
                    <div className="settings-sidebar-header">
                        Settings
                    </div>
                    <div className="flex-1 overflow-y-auto">
                        {categories.map(cat => (
                            <div
                                key={cat.id}
                                className={`settings-nav-item ${selectedCategory === cat.id ? 'active' : ''}`}
                                onClick={() => setSelectedCategory(cat.id)}
                            >
                                <cat.icon className="settings-nav-icon" />
                                {cat.label}
                            </div>
                        ))}
                    </div>
                </div>

                {/* Content */}
                <div className="settings-content">
                    <div className="settings-content-header">
                        <button className="close-button" onClick={onClose}>
                            <X size={24} />
                        </button>
                    </div>
                    <div className="settings-scroll-area">
                        <h2 className="settings-page-title">
                            {categories.find(c => c.id === selectedCategory)?.label}
                        </h2>
                        {renderContent()}
                    </div>
                </div>
            </div>
        </div>
    );
};
