import React, { createContext, useContext, useEffect, useState } from 'react';
import { authService } from '../services/auth';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        // Handle OAuth Callback in URL if present
        const handleCallback = async () => {
            const params = new URLSearchParams(window.location.search);
            const code = params.get('code');
            if (code) {
                // Clear code from URL to prevent loop/dirty URL
                window.history.replaceState({}, document.title, window.location.pathname);
                await authService.handleAuthCallback(code);
            }
        };

        const checkAuth = async () => {
            await handleCallback();

            // Allow service a tick to sync
            setTimeout(() => {
                if (authService.isLoggedIn()) {
                    setUser(authService.getUser());
                    setIsAuthenticated(true);
                }
                setIsLoading(false);
            }, 500);
        };

        checkAuth();
    }, []);

    const login = async (email, pass) => {
        setIsLoading(true);
        try {
            const user = await authService.login(email, pass);
            setUser(user);
            setIsAuthenticated(true);
        } finally {
            setIsLoading(false);
        }
    };

    const loginWithGoogle = async () => {
        await authService.signInWithGoogle();
    };

    const logout = () => {
        authService.logout();
        setUser(null);
        setIsAuthenticated(false);
    };

    const value = {
        user,
        isAuthenticated,
        login,
        loginWithGoogle,
        logout,
        isLoading
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
