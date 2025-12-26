import React, { useState } from 'react';
import { MainLayout } from './MainLayout';
import { Sidebar, ViewType } from './Sidebar/Sidebar';
import { TitleBar } from './TitleBar';
import { HomeView } from './Views/HomeView';
import { DictionaryView } from './Views/DictionaryView';
import { SnippetsView } from './Views/SnippetsView';
import { StyleView } from './Views/StyleView';
import { NotesView } from './Views/NotesView';
import { SettingsView } from '../Settings/SettingsView';
import { SettingsCategory } from '../Settings/types';

export const MainView: React.FC = () => {
    const [currentView, setCurrentView] = useState<ViewType>('home');
    const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
    const [isSettingsOpen, setIsSettingsOpen] = useState(false);
    const [settingsTab, setSettingsTab] = useState<SettingsCategory>('account');

    const toggleSidebar = () => setIsSidebarCollapsed(prev => !prev);

    const openSettings = (tab: SettingsCategory = 'account') => {
        setSettingsTab(tab);
        setIsSettingsOpen(true);
    };

    const renderContent = () => {
        switch (currentView) {
            case 'home': return <HomeView />;
            case 'dictionary': return <DictionaryView />;
            case 'snippets': return <SnippetsView />;
            case 'style': return <StyleView />;
            case 'notes': return <NotesView />;
            // Settings case removed as it's now a modal
            default: return <HomeView />;
        }
    };

    return (
        <MainLayout
            titleBar={
                <TitleBar
                    toggleSidebar={toggleSidebar}
                    isSidebarCollapsed={isSidebarCollapsed}
                    onManageAccount={() => openSettings('account')}
                />
            }
            sidebar={
                <Sidebar
                    currentView={currentView}
                    onViewChange={setCurrentView}
                    isCollapsed={isSidebarCollapsed}
                    onOpenSettings={openSettings}
                />
            }
        >
            {renderContent()}
            {isSettingsOpen && <SettingsView onClose={() => setIsSettingsOpen(false)} initialTab={settingsTab} />}
        </MainLayout>
    );
};
