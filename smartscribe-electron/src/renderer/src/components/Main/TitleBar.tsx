import React from 'react';
import { PanelLeft } from 'lucide-react';
import { UserMenu } from './UserMenu';
import './TitleBar.css';

interface TitleBarProps {
    toggleSidebar: () => void;
    isSidebarCollapsed: boolean;
    onManageAccount?: () => void;
}

export const TitleBar: React.FC<TitleBarProps> = ({ toggleSidebar, onManageAccount }) => {
    return (
        <div className="titlebar">
            <button className="sidebar-toggle" onClick={toggleSidebar}>
                <PanelLeft size={20} />
            </button>

            {/* Spacer */}
            <div style={{ flex: 1 }}></div>

            {/* User Menu */}
            <div style={{ WebkitAppRegion: 'no-drag', marginRight: '10px' } as any}>
                <UserMenu onManageAccount={onManageAccount} />
            </div>
        </div>
    );
};
