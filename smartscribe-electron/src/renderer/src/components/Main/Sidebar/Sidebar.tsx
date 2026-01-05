import React, { useState, useEffect } from 'react';
import { LayoutGrid, Book, Scissors, Type, StickyNote, Settings, HelpCircle, UserPlus, Gift, Info, Smartphone, Command, Mic, Globe, LifeBuoy, MessageSquare, Briefcase } from 'lucide-react';
import clsx from 'clsx';
import { SettingsCategory } from '../../Settings/types';
import { TicketModal } from '../../Shared/TicketModal';
import { configService } from '../../../services/api/config';
import { LanguageModal } from '../../Shared/LanguageModal/LanguageModal';
import { MicrophoneModal } from '../../Shared/MicrophoneModal/MicrophoneModal';
import { ShortcutsModal } from '../../Shared/ShortcutsModal/ShortcutsModal';
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
    const [showTicketModal, setShowTicketModal] = useState(false);
    const [showLanguageModal, setShowLanguageModal] = useState(false);
    const [showMicrophoneModal, setShowMicrophoneModal] = useState(false);
    const [showShortcutsModal, setShowShortcutsModal] = useState(false);
    const [selectedLanguages, setSelectedLanguages] = useState<Set<string>>(new Set(['en']));

    // Shortcut keys state
    const [pushToTalkKey, setPushToTalkKey] = useState<string>('Fn');
    const [handsFreeModeKey, setHandsFreeModeKey] = useState<string>('Cmd+Shift+H');
    const [commandModeKey, setCommandModeKey] = useState<string>('Ctrl+Space');

    // Load settings on mount
    useEffect(() => {
        loadShortcutSettings();
    }, []);

    const loadShortcutSettings = async () => {
        try {
            const settings = await configService.getSettings();
            if (settings.pushToTalkKey) setPushToTalkKey(settings.pushToTalkKey);
            if (settings.handsFreeModeKey) setHandsFreeModeKey(settings.handsFreeModeKey);
            if (settings.commandModeKey) setCommandModeKey(settings.commandModeKey);
        } catch (error) {
            console.error('Failed to load shortcut settings:', error);
        }
    };

    const handleHelpItemClick = async (itemId: string) => {
        console.log('Help item clicked:', itemId);
        setShowHelpMenu(false);

        if (itemId === 'support') {
            setShowTicketModal(true);
        } else if (itemId === 'languages') {
            try {
                const settings = await configService.getSettings();
                if (settings.languages && Array.isArray(settings.languages)) {
                    setSelectedLanguages(new Set(settings.languages));
                }
                setShowLanguageModal(true);
            } catch (error) {
                console.error('Failed to fetch languages:', error);
                setShowLanguageModal(true);
            }
        } else if (itemId === 'microphone') {
            setShowMicrophoneModal(true);
        } else if (itemId === 'shortcuts') {
            setShowShortcutsModal(true);
        }
        // TODO: Implement other help items
    };

    const handleInviteTeam = () => {
        onOpenSettings('team');
    };

    const handleGetFreeMonth = () => {
        setShowInviteModal(true);
    };

    const handleLanguageToggle = (id: string) => {
        setSelectedLanguages(prev => {
            const next = new Set(prev);
            if (next.has(id)) {
                next.delete(id);
            } else {
                next.add(id);
            }
            return next;
        });
    };

    const handleSaveLanguages = async () => {
        try {
            await configService.updateSettings({
                languages: Array.from(selectedLanguages)
            });
            setShowLanguageModal(false);
        } catch (error) {
            console.error('Failed to save languages:', error);
        }
    };

    const handleSaveShortcut = async (key: 'pushToTalkKey' | 'handsFreeModeKey' | 'commandModeKey', value: string) => {
        try {
            // Update local state
            if (key === 'pushToTalkKey') setPushToTalkKey(value);
            else if (key === 'handsFreeModeKey') setHandsFreeModeKey(value);
            else if (key === 'commandModeKey') setCommandModeKey(value);

            // Save to backend
            await configService.updateSettings({ [key]: value });
        } catch (error) {
            console.error('Failed to save shortcut:', error);
        }
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
                                    <span className="flow-logo">III Scribe</span>
                                    <span className="pro-badge">Pro</span>
                                </div>
                                <div className="invite-card-subtitle">UNLIMITED WORDS FOR 1 MONTH</div>
                                <div className="invite-card-footer">Gifted by smartscribe</div>
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
                                        value="https://smartscribe.app/?TUCICOVENCO1"
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

            {/* Ticket Modal */}
            <TicketModal
                isOpen={showTicketModal}
                onClose={() => setShowTicketModal(false)}
            />

            {/* Language Modal */}
            <LanguageModal
                isOpen={showLanguageModal}
                onClose={() => setShowLanguageModal(false)}
                selectedIds={selectedLanguages}
                onToggle={handleLanguageToggle}
                onSave={handleSaveLanguages}
                darkTheme={true}
            />

            {/* Microphone Modal */}
            <MicrophoneModal
                isOpen={showMicrophoneModal}
                onClose={() => setShowMicrophoneModal(false)}
            />

            {/* Shortcuts Modal */}
            <ShortcutsModal
                isOpen={showShortcutsModal}
                onClose={() => setShowShortcutsModal(false)}
                pushToTalkKey={pushToTalkKey}
                handsFreeModeKey={handsFreeModeKey}
                commandModeKey={commandModeKey}
                onSave={handleSaveShortcut}
            />
        </>
    );
};
