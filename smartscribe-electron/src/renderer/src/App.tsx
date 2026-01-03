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
    const { isAuthenticated, loginWithGoogle, user, isLoading } = useAuth(); // Use context

    useEffect(() => {
        if (user?.onboarding) {
            setHasCompletedOnboarding(true);
            if ((window as any).electron) {
                (window as any).electron.ipcRenderer.resizeWindow(900, 670);
                // Open the Floating Waveform automatically for authenticated users
                (window as any).electron.ipcRenderer.openWaveform();
            }
        }
    }, [user]);

    // Simple check on mount
    useEffect(() => {
        // Listen for deep links
        let removeListener: (() => void) | undefined;

        if ((window as any).electron) {
            removeListener = (window as any).electron.ipcRenderer.on('deep-link', (url: string) => {
                console.log('App.tsx: Received deep link:', url);
                authService.handleAuthCallback(url).then((success) => {
                    console.log('App.tsx: handleAuthCallback result:', success);
                    if (success) {
                        console.log('App.tsx: Authentication successful, reloading...');
                        window.location.reload();
                    } else {
                        console.error('App.tsx: Authentication failed or URL invalid');
                    }
                }).catch(err => {
                    console.error('App.tsx: handleAuthCallback error:', err);
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

    if (isLoading) {
        return (
            <div className="app-loading">
                <div className="loading-spinner"></div>
            </div>
        );
    }

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
