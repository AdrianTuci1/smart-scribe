import { useState, useEffect } from 'react';
import { HashRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import { OnboardingView } from './components/Onboarding/OnboardingView';
import { MainView } from './components/Main/MainView';
import { FloatingWaveform } from './components/Waveform/FloatingWaveform';
import { LoginView } from './components/Auth/LoginView';

const MainApp = () => {
    const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);
    const [isAuthenticated, setIsAuthenticated] = useState(false);

    // Simple check on mount
    useEffect(() => {
        // Here we would check persistence for onboarding
        // And auth service for token
        import('./services/auth').then(({ authService }) => {
            setIsAuthenticated(authService.isLoggedIn());
        });
    }, []);

    const handleOnboardingComplete = () => {
        setHasCompletedOnboarding(true);
        window.electron.ipcRenderer.resizeWindow(900, 670);
    };

    const handleLoginSuccess = () => {
        setIsAuthenticated(true);
    };

    if (!hasCompletedOnboarding) {
        return <OnboardingView onComplete={handleOnboardingComplete} />;
    }

    if (!isAuthenticated) {
        return <LoginView onLoginSuccess={handleLoginSuccess} />;
    }

    return <MainView />;
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
