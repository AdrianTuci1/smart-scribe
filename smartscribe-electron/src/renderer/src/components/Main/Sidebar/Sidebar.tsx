import React from 'react';
import { LayoutGrid, Book, Scissors, Type, StickyNote, Settings, HelpCircle, UserPlus, Calendar } from 'lucide-react';
import clsx from 'clsx';
import './Sidebar.css';

export type ViewType = 'home' | 'dictionary' | 'snippets' | 'style' | 'notes' | 'settings';

interface SidebarProps {
    currentView: ViewType;
    onViewChange: (view: ViewType) => void;
    isCollapsed: boolean;
}

const MENU_ITEMS = [
    { id: 'home', label: 'Home', icon: LayoutGrid },
    { id: 'dictionary', label: 'Dictionary', icon: Book },
    { id: 'snippets', label: 'Snippets', icon: Scissors },
    { id: 'style', label: 'Style', icon: Type },
    { id: 'notes', label: 'Notes', icon: StickyNote },
] as const;

export const Sidebar: React.FC<SidebarProps> = ({ currentView, onViewChange, isCollapsed }) => {
    return (
        <div className={clsx("sidebar", isCollapsed ? "collapsed" : "expanded")}>
            <div className="flex-1">
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

            <div className="border-t border-gray-200 dark:border-gray-800 pt-2 pb-2">
                <div
                    className={clsx("sidebar-item", currentView === 'settings' && "active")}
                    onClick={() => onViewChange('settings')}
                >
                    <Settings className="sidebar-icon" />
                    <span className="sidebar-label">Settings</span>
                </div>
            </div>
        </div>
    );
};
