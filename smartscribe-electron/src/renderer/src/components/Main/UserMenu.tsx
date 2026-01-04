import React, { useState, useRef, useEffect } from 'react';
import { User, Bell, Smartphone, QrCode } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { apiService } from '../../services/api';
import './UserMenu.css';

interface UserMenuProps {
    onManageAccount?: () => void;
}

export const UserMenu: React.FC<UserMenuProps> = ({
    onManageAccount
}) => {
    const { user } = useAuth();
    const [isOpen, setIsOpen] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);

    // Derived values
    const [stats, setStats] = useState({ used: 0, limit: 2000, plan: 'free' });

    const userName = user?.username || 'Guest';
    const userEmail = user?.email || 'guest@example.com';
    const userAvatar = undefined; // We don't have avatar in Cognito yet

    const planName = stats.plan === 'pro' || stats.plan === 'yearly' ? 'Pro' : 'Basic';
    const wordsUsed = stats.used;
    const wordsLimit = stats.limit;

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        };

        if (isOpen) {
            document.addEventListener('mousedown', handleClickOutside);
            // Fetch usage
            apiService.getUserStats().then(data => {
                if (data) {
                    setStats({
                        used: data.usage?.wordsUsed || 0,
                        limit: data.usage?.limit || 2000,
                        plan: data.plan || 'free'
                    });
                }
            }).catch(console.error);
        }

        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [isOpen]);

    const toggleMenu = () => {
        setIsOpen(!isOpen);
    };

    return (
        <div className="user-menu-container" ref={menuRef}>
            {/* Trigger Button */}
            <button className="user-menu-trigger" onClick={toggleMenu}>
                {userAvatar ? (
                    <img src={userAvatar} alt={userName} className="user-avatar" />
                ) : (
                    <div className="user-avatar-placeholder">
                        <User size={18} />
                    </div>
                )}
            </button>

            {/* Dropdown Menu */}
            {isOpen && (
                <div className="user-menu-dropdown">
                    {/* User Profile Section */}
                    <div className="user-menu-section user-profile">
                        <div className="user-profile-avatar">
                            {userAvatar ? (
                                <img src={userAvatar} alt={userName} />
                            ) : (
                                <div className="user-avatar-placeholder-large">
                                    <User size={32} />
                                </div>
                            )}
                        </div>
                        <div className="user-profile-info">
                            <div className="user-name">{userName}</div>
                            <div className="user-email">{userEmail}</div>
                        </div>
                    </div>

                    {/* Plan Status Section */}
                    <div className="user-menu-section plan-status">
                        <div className="plan-info">
                            <div className="plan-name">You are on {planName}</div>
                            <div className="plan-usage">
                                {wordsUsed.toLocaleString()} of {wordsLimit.toLocaleString()} words left this week
                            </div>
                        </div>
                        <button className="plan-upgrade-button">Get Scribe Pro</button>
                    </div>

                    {/* Referral Section */}
                    <div className="user-menu-section referral-section">
                        <div className="referral-info">
                            <div className="referral-title">Get a free month of Scribe Pro</div>
                            <div className="referral-subtitle">Refer friends, earn rewards</div>
                        </div>
                        <button className="referral-button">Refer a friend</button>
                    </div>

                    {/* iOS Download Section */}
                    <div className="user-menu-section ios-download">
                        <div className="ios-download-info">
                            <Smartphone size={20} />
                            <span>Download Scribe for iOS</span>
                        </div>
                        <QrCode size={20} className="qr-icon" />
                    </div>

                    {/* Manage Account */}
                    <div className="user-menu-section manage-account">
                        <button
                            className="manage-account-button"
                            onClick={() => {
                                if (onManageAccount) {
                                    onManageAccount();
                                    setIsOpen(false);
                                }
                            }}
                        >
                            Manage account
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};
