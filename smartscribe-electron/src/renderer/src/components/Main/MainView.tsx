import React, { useState } from 'react';
import { MainLayout } from './MainLayout';
import { Sidebar, ViewType } from './Sidebar/Sidebar';
import { TitleBar } from './TitleBar';
import { HomeView } from './Views/HomeView';
import { DictionaryView } from './Views/DictionaryView';
import { SnippetsView } from './Views/SnippetsView';
import { StyleView } from './Views/StyleView';
import { NotesView } from './Views/NotesView';
import { SettingsView } from './Views/SettingsView';

export const MainView: React.FC = () => {
    const [currentView, setCurrentView] = useState<ViewType>('home');
    const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

    const toggleSidebar = () => setIsSidebarCollapsed(prev => !prev);

    const renderContent = () => {
        switch (currentView) {
            case 'home': return <HomeView />;
            case 'dictionary': return <DictionaryView />;
            case 'snippets': return <SnippetsView />;
            case 'style': return <StyleView />;
            case 'notes': return <NotesView />;
            case 'settings': return <SettingsView />;
            default: return <HomeView />;
        }
    };

    return (
        <MainLayout
            titleBar={<TitleBar toggleSidebar={toggleSidebar} isSidebarCollapsed={isSidebarCollapsed} />}
            sidebar={
                <Sidebar
                    currentView={currentView}
                    onViewChange={setCurrentView}
                    isCollapsed={isSidebarCollapsed}
                />
            }
        >
            {renderContent()}
        </MainLayout>
    );
};
