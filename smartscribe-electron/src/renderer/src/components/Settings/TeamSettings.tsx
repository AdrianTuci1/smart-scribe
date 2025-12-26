import React from 'react';
import { Users } from 'lucide-react';
import { SettingsTabProps } from './types';

export const TeamSettings: React.FC<SettingsTabProps> = () => {
    return (
        <>
            <div className="settings-section">
                <h3 className="settings-section-title">Invite Your Teammates</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '80px' }}>Email 1</span>
                        <input type="email" className="settings-input" placeholder="Enter email address" />
                    </div>
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '80px' }}>Email 2</span>
                        <input type="email" className="settings-input" placeholder="Enter email address" />
                    </div>
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '80px' }}>Email 3</span>
                        <input type="email" className="settings-input" placeholder="Enter email address" />
                    </div>
                    <div className="settings-row">
                        <div style={{ flex: 1 }}></div>
                        <button className="settings-button primary">Send Invitations</button>
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Team Members</h3>
                <div className="settings-card">
                    <div className="empty-state">
                        <Users size={24} style={{ opacity: 0.5 }} />
                        <span>No team members yet</span>
                    </div>
                </div>
            </div>
        </>
    );
};
