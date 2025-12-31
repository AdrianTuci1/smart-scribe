import { useState, useEffect } from 'react';
import { HashRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import { OnboardingView } from './components/Onboarding/OnboardingView';
import { authService } from './services/auth';
import { MainView } from './components/Main/MainView';
import { FloatingWaveform } from './components/Waveform/FloatingWaveform';
import { Settings as SettingsIcon } from 'lucide-react';
import { Link } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';

import './App.css';

const MainAppContent = () => {
    const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);
    const { isAuthenticated, loginWithGoogle, user } = useAuth(); // Use context

    useEffect(() => {
        if (user?.onboarding) {
            setHasCompletedOnboarding(true);
            if ((window as any).electron) {
                (window as any).electron.ipcRenderer.resizeWindow(900, 670);
                // Open the Floating Waveform automatically? Maybe not on every reload, but specific flow.
                // Keeping existing behavior for "Complete" flow, but for reload we might just want to set state.
            }
        }
    }, [user]);

    // Simple check on mount
    useEffect(() => {
        // Listen for deep links
        let removeListener: (() => void) | undefined;

        if ((window as any).electron) {
            removeListener = (window as any).electron.ipcRenderer.on('deep-link', (url: string) => {
                console.log('Received deep link:', url);
                authService.handleAuthCallback(url).then((success) => {
                    if (success) {
                        // Ideally we should reload or update context. 
                        // Since authService updates internal state, and we reload on logout...
                        // We might want to trigger a refresh.
                        window.location.reload();
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

    if (!hasCompletedOnboarding) {
        return <OnboardingView onComplete={handleOnboardingComplete} />;
    }

    return (
        <div className="app-container">
            <MainView />
        </div>
    );
};

const MainApp = () => {
    return (
        <AuthProvider>
            <MainAppContent />
        </AuthProvider>
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
