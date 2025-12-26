import React, { useState } from 'react';
import { LayoutGrid, Book, Scissors, Type, StickyNote, Settings, HelpCircle, UserPlus, Gift, Info, Smartphone, Command, Mic, Globe, LifeBuoy, MessageSquare, Briefcase } from 'lucide-react';
import clsx from 'clsx';
import { SettingsCategory } from '../../Settings/types';
import './Sidebar.css';

export type ViewType = 'home' | 'dictionary' | 'snippets' | 'style' | 'notes';

interface SidebarProps {
    currentView: ViewType;
    onViewChange: (view: ViewType) => void;
    isCollapsed: boolean;
    onOpenSettings: (tab?: SettingsCategory) => void;
}

const MENU_ITEMS = [
    { id: 'home', label: 'Home', icon: LayoutGrid },
    { id: 'dictionary', label: 'Dictionary', icon: Book },
    { id: 'snippets', label: 'Snippets', icon: Scissors },
    { id: 'style', label: 'Style', icon: Type },
    { id: 'notes', label: 'Notes', icon: StickyNote },
] as const;

const HELP_MENU_ITEMS = [
    {
        section: "What's New", items: [
            { id: 'release-notes', label: 'Release notes', icon: Info },
            { id: 'ios-app', label: 'Try iOS app', icon: Smartphone },
        ]
    },
    {
        section: "Essentials", items: [
            { id: 'shortcuts', label: 'Shortcuts', icon: Command },
            { id: 'microphone', label: 'Microphone', icon: Mic },
            { id: 'languages', label: 'Languages', icon: Globe },
        ]
    },
    {
        section: "Get in touch", items: [
            { id: 'help-center', label: 'Help Center', icon: LifeBuoy },
            { id: 'support', label: 'Talk to support', icon: MessageSquare },
            { id: 'sales', label: 'Contact sales', icon: Briefcase },
        ]
    },
];

export const Sidebar: React.FC<SidebarProps> = ({ currentView, onViewChange, isCollapsed, onOpenSettings }) => {
    const [showHelpMenu, setShowHelpMenu] = useState(false);
    const [showInviteModal, setShowInviteModal] = useState(false);

    const handleHelpItemClick = (itemId: string) => {
        console.log('Help item clicked:', itemId);
        setShowHelpMenu(false);
        // TODO: Implement actual navigation/actions for help items
    };

    const handleInviteTeam = () => {
        onOpenSettings('team');
    };

    const handleGetFreeMonth = () => {
        setShowInviteModal(true);
    };

    return (
        <>
            <div className={clsx("sidebar", isCollapsed ? "collapsed" : "expanded")}>
                <div className="sidebar-main-menu">
                    {MENU_ITEMS.map((item) => {
                        const Icon = item.icon;
                        return (
                            <div
                                key={item.id}
                                className={clsx("sidebar-item", currentView === item.id && "active")}
                                onClick={() => onViewChange(item.id)}
                            >
                                <Icon className="sidebar-icon" />
                                <span className="sidebar-label">{item.label}</span>
                            </div>
                        );
                    })}
                </div>

                <div className="sidebar-bottom-menu">
                    <div
                        className="sidebar-item"
                        onClick={handleInviteTeam}
                    >
                        <UserPlus className="sidebar-icon" />
                        <span className="sidebar-label">Invite your team</span>
                    </div>

                    <div
                        className="sidebar-item"
                        onClick={handleGetFreeMonth}
                    >
                        <Gift className="sidebar-icon" />
                        <span className="sidebar-label">Get a free month</span>
                    </div>

                    <div
                        className="sidebar-item"
                        onClick={() => onOpenSettings('general')}
                    >
                        <Settings className="sidebar-icon" />
                        <span className="sidebar-label">Settings</span>
                    </div>

                    <div
                        className="sidebar-item"
                        onClick={() => setShowHelpMenu(!showHelpMenu)}
                    >
                        <HelpCircle className="sidebar-icon" />
                        <span className="sidebar-label">Help</span>
                    </div>
                </div>
            </div>

            {/* Help Menu Modal */}
            {showHelpMenu && (
                <>
                    <div
                        className="help-menu-overlay"
                        onClick={() => setShowHelpMenu(false)}
                    />
                    <div className="help-menu-modal">
                        {HELP_MENU_ITEMS.map((section, idx) => (
                            <div key={idx} className="help-menu-section">
                                <div className="help-menu-section-title">{section.section}</div>
                                {section.items.map((item) => {
                                    const Icon = item.icon;
                                    return (
                                        <div
                                            key={item.id}
                                            className="help-menu-item"
                                            onClick={() => handleHelpItemClick(item.id)}
                                        >
                                            <Icon className="help-menu-icon" />
                                            <span>{item.label}</span>
                                        </div>
                                    );
                                })}
                            </div>
                        ))}
                    </div>
                </>
            )}

            {/* Invite Modal */}
            {showInviteModal && (
                <>
                    <div
                        className="invite-modal-overlay"
                        onClick={() => setShowInviteModal(false)}
                    />
                    <div className="invite-modal">
                        <div className="invite-modal-header">
                            <h2>Refer and earn rewards</h2>
                            <p>Give a month of Pro and get 1 month for each person you refer.</p>
                        </div>

                        <div className="invite-modal-tabs">
                            <button className="invite-tab active">Refer</button>
                            <button className="invite-tab">Past invites (0)</button>
                        </div>

                        <div className="invite-modal-content">
                            <div className="invite-card">
                                <div className="invite-card-badge">
                                    <span className="flow-logo">III Flow</span>
                                    <span className="pro-badge">Pro</span>
                                </div>
                                <div className="invite-card-subtitle">UNLIMITED WORDS FOR 1 MONTH</div>
                                <div className="invite-card-footer">Gifted by flowscribe</div>
                            </div>

                            <div className="invite-how-it-works">
                                <h3>How it works</h3>
                                <div className="invite-step">
                                    <Command className="invite-step-icon" />
                                    <span>Share your invite link</span>
                                </div>
                                <div className="invite-step">
                                    <UserPlus className="invite-step-icon" />
                                    <span>They sign up and get a free month of Pro!</span>
                                </div>
                                <div className="invite-step">
                                    <Gift className="invite-step-icon" />
                                    <span>You get a free month when they dictate 2,000 words!</span>
                                </div>
                            </div>

                            <div className="invite-link-section">
                                <label>Your invite link</label>
                                <div className="invite-link-input">
                                    <input
                                        type="text"
                                        value="https://wisprflow.ai/?TUCICOVENCO1"
                                        readOnly
                                    />
                                    <button className="copy-button">Copy</button>
                                </div>
                            </div>

                            <div className="invite-email-section">
                                <label>Send invites</label>
                                <div className="invite-email-input">
                                    <input
                                        type="email"
                                        placeholder="email@example.com"
                                    />
                                    <button className="send-button">Send</button>
                                </div>
                            </div>

                            <div className="invite-disclaimer">
                                Rewards auto-applied to the next subscription payment.<br />
                                You must subscribe via the desktop app to claim your rewards.
                            </div>
                        </div>
                    </div>
                </>
            )}
        </>
    );
};
