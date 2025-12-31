import React from 'react';
import { ChevronRight, Trash } from 'lucide-react';
import { SettingsTabProps } from './types';

export const AccountSettings: React.FC<SettingsTabProps> = () => {
    return (
        <>
            <div className="user-profile-header">
                <div className="user-avatar">AT</div>
                <div className="user-info">
                    <div className="user-name">Adrian Tucicovenco</div>
                    <div className="user-email">adrian.tucicovenco@gmail.com</div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Profile Information</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '120px' }}>First Name</span>
                        <input type="text" className="settings-input" defaultValue="Adrian" />
                    </div>
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '120px' }}>Last Name</span>
                        <input type="text" className="settings-input" defaultValue="Tucicovenco" />
                    </div>
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '120px' }}>Email</span>
                        <input type="email" className="settings-input" defaultValue="adrian.tucicovenco@gmail.com" />
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Account Actions</h3>
                <div className="settings-card">
                    <button className="settings-action-button">
                        <span>Sign Out</span>
                        <ChevronRight size={18} />
                    </button>
                    <button className="settings-action-button danger">
                        <Trash size={18} />
                        <span>Delete Account</span>
                    </button>
                </div>
            </div>
        </>
    );
};
