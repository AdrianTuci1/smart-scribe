import React from 'react';
import { PanelLeft } from 'lucide-react';
import './TitleBar.css';

interface TitleBarProps {
    toggleSidebar: () => void;
    isSidebarCollapsed: boolean;
}

export const TitleBar: React.FC<TitleBarProps> = ({ toggleSidebar }) => {
    return (
        <div className="titlebar">
            <button className="sidebar-toggle" onClick={toggleSidebar}>
                <PanelLeft size={20} />
            </button>

            {/* Spacer */}
            <div style={{ flex: 1 }}></div>

            {/* User Menu Placeholder */}
            <div className="user-menu-placeholder" style={{ WebkitAppRegion: 'no-drag' } as any}>
                {/* User Icon or Button */}
            </div>
        </div>
    );
};
