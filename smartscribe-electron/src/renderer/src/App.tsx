import { useState, useEffect } from 'react';
import { HashRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import { OnboardingView } from './components/Onboarding/OnboardingView';
import { authService } from './services/auth';
import { MainView } from './components/Main/MainView';
import { FloatingWaveform } from './components/Waveform/FloatingWaveform';
import { Settings as SettingsIcon } from 'lucide-react';
import { Link } from 'react-router-dom';

import './App.css';

const MainApp = () => {
    const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);
    const [isAuthenticated, setIsAuthenticated] = useState(false);

    // Simple check on mount
    useEffect(() => {
        // Here we would check persistence for onboarding
        // And auth service for token
        setIsAuthenticated(authService.isLoggedIn());

        // Listen for deep links
        let removeListener: (() => void) | undefined;

        if ((window as any).electron) {
            removeListener = (window as any).electron.ipcRenderer.on('deep-link', (url: string) => {
                console.log('Received deep link:', url);
                authService.handleAuthCallback(url).then((success) => {
                    if (success) {
                        setIsAuthenticated(true);
                        // Force window focus or UI update if needed
                    }
                });
            });
        }


        return () => {
            if (removeListener) removeListener();
        };
    }, []);

    const handleOnboardingComplete = () => {
        setHasCompletedOnboarding(true);
        if ((window as any).electron) {
            (window as any).electron.ipcRenderer.resizeWindow(900, 670);
            // Open the Floating Waveform automatically
            (window as any).electron.ipcRenderer.openWaveform();
        }
    };

    const handleLoginSuccess = () => {
        setIsAuthenticated(true);
    };

    if (!hasCompletedOnboarding) {
        return <OnboardingView onComplete={handleOnboardingComplete} />;
    }

    // Allow guest access (skip login) - we don't block on !isAuthenticated anymore
    // Authentication can happen during onboarding or via Settings later


    return (
        <div className="app-container">
            <MainView />

            {/* Temporary Floating Settings Button for Access */}
            <Link
                to="/settings"
                className="settings-button"
            >
                <SettingsIcon size={20} className="settings-icon" />
            </Link>
        </div>
    );
};


function App() {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<MainApp />} />
                <Route path="/waveform" element={<FloatingWaveform />} />
            </Routes>
        </Router>
    );
}

export default App;
