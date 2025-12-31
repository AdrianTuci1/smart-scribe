import React from 'react';
import { ChevronRight, Trash } from 'lucide-react';
import { SettingsTabProps } from './types';
import { useAuth } from '../../contexts/AuthContext';

export const AccountSettings: React.FC<SettingsTabProps> = () => {
    const { user, logout, deleteAccount } = useAuth();

    return (
        <>
            <div className="user-profile-header">
                <div className="user-avatar">{user?.username?.substring(0, 2).toUpperCase() || 'AT'}</div>
                <div className="user-info">
                    <div className="user-name">{user?.username || 'Adrian Tucicovenco'}</div>
                    <div className="user-email">{user?.email || 'adrian.tucicovenco@gmail.com'}</div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Profile Information</h3>
                <div className="settings-card">
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '120px' }}>Username</span>
                        <input type="text" className="settings-input" defaultValue={user?.username || ''} readOnly />
                    </div>
                    {/*
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '120px' }}>Last Name</span>
                        <input type="text" className="settings-input" defaultValue="Tucicovenco" />
                    </div>
                    */}
                    <div className="settings-row">
                        <span className="row-label" style={{ width: '120px' }}>Email</span>
                        <input type="email" className="settings-input" defaultValue={user?.email || ''} readOnly />
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Account Actions</h3>
                <div className="settings-card">
                    <button className="settings-action-button" onClick={logout}>
                        <span>Sign Out</span>
                        <ChevronRight size={18} />
                    </button>
                    <button className="settings-action-button danger" onClick={() => {
                        if (window.confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
                            deleteAccount();
                        }
                    }}>
                        <Trash size={18} />
                        <span>Delete Account</span>
                    </button>
                </div>
            </div>
        </>
    );
};
