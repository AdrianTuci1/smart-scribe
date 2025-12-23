import React from 'react';

export const HomeView: React.FC = () => {
    return (
        <div className="p-8">
            <h1 className="text-2xl font-bold mb-4">Home</h1>
            <p className="text-gray-600 dark:text-gray-400">Welcome to your dashboard.</p>

            <button
                onClick={() => window.electron.ipcRenderer.invoke('open-waveform')}
                className="mt-4 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
            >
                Open Floating Waveform
            </button>
        </div>
    );
};
