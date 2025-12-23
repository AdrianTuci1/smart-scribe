import React from 'react';
import './MainLayout.css';

interface MainLayoutProps {
    sidebar: React.ReactNode;
    children: React.ReactNode;
    titleBar: React.ReactNode;
}

export const MainLayout: React.FC<MainLayoutProps> = ({ sidebar, children, titleBar }) => {
    return (
        <div className="main-layout">
            {sidebar}
            <div className="main-content">
                <div className="content-area">
                    {children}
                </div>
            </div>
            {titleBar}
        </div>
    );
};
