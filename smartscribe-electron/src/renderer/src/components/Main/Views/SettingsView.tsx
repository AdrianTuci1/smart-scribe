import { useState, useEffect } from 'react';
import { User, Bell, Shield, Keyboard, Mic } from 'lucide-react';
import clsx from 'clsx';

type SettingsTab = 'general' | 'audio' | 'account' | 'about';

export const SettingsView = () => {
    const [activeTab, setActiveTab] = useState<SettingsTab>('general');
    const [settings, setSettings] = useState<any>({});

    useEffect(() => {
        // Load settings
        window.electron.getAllSettings().then(setSettings);
    }, []);

    const updateSetting = (key: string, value: any) => {
        const newSettings = { ...settings, [key]: value };
        setSettings(newSettings);
        window.electron.setSetting(key, value);
    };

    const tabs = [
        { id: 'general', label: 'General', icon: Keyboard },
        { id: 'audio', label: 'Audio', icon: Mic },
        { id: 'account', label: 'Account', icon: User },
        { id: 'about', label: 'About', icon: Shield }, // Using Shield as placeholder for About
    ];

    return (
        <div className="flex h-full bg-gray-50 dark:bg-gray-900">
            {/* Sidebar */}
            <div className="w-64 border-r border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 pt-6">
                <h2 className="px-6 text-lg font-bold mb-6">Settings</h2>
                <div className="space-y-1 px-3">
                    {tabs.map(tab => {
                        const Icon = tab.icon;
                        return (
                            <button
                                key={tab.id}
                                onClick={() => setActiveTab(tab.id as SettingsTab)}
                                className={clsx(
                                    "w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors",
                                    activeTab === tab.id
                                        ? "bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400"
                                        : "text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                                )}
                            >
                                <Icon size={18} />
                                {tab.label}
                            </button>
                        );
                    })}
                </div>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-8">
                <div className="max-w-2xl">
                    <h1 className="text-2xl font-bold mb-8 capitalize">{activeTab} Settings</h1>

                    {activeTab === 'general' && (
                        <div className="space-y-6">
                            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm border border-gray-200 dark:border-gray-700">
                                <h3 className="font-medium mb-4">Application</h3>
                                <div className="flex items-center justify-between">
                                    <div>
                                        <div className="font-medium">Launch at Login</div>
                                        <div className="text-sm text-gray-500">Automatically start SmartScribe when you log in</div>
                                    </div>
                                    <input
                                        type="checkbox"
                                        checked={settings.launchAtLogin || false}
                                        onChange={(e) => updateSetting('launchAtLogin', e.target.checked)}
                                        className="toggle"
                                    />
                                </div>
                            </div>
                        </div>
                    )}

                    {activeTab === 'audio' && (
                        <div className="space-y-6">
                            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm border border-gray-200 dark:border-gray-700">
                                <h3 className="font-medium mb-4">Microphone</h3>
                                <div className="space-y-4">
                                    <label className="block">
                                        <span className="text-sm text-gray-700 dark:text-gray-300 mb-1 block">Input Device</span>
                                        <select
                                            className="w-full bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-700 rounded-lg px-3 py-2"
                                            value={settings.selectedMicrophone || 'default'}
                                            onChange={(e) => updateSetting('selectedMicrophone', e.target.value)}
                                        >
                                            <option value="default">Default System Microphone</option>
                                            <option value="mic1">External Microphone 1</option>
                                        </select>
                                    </label>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};
