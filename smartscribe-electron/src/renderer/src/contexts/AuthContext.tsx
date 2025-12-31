import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { authService, User } from '../services/auth';
import { configService } from '../services/api';

interface AuthContextType {
    user: User | null;
    isAuthenticated: boolean;
    login: (email: string, pass: string) => Promise<void>;
    loginWithGoogle: () => Promise<void>;
    logout: () => void;
    deleteAccount: () => Promise<void>;
    isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
    const [user, setUser] = useState<User | null>(null);
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [isLoading, setIsLoading] = useState(true);

    // Initial check
    useEffect(() => {
        const checkAuth = async () => {
            // Give the auth service a moment to check session (which is async in constructor/init)
            // But since authService.checkCurrentSession is void and kicked off in constructor, 
            // we might need to poll or listen.
            // For now, let's just rely on a simple interval or immediate check if token exists.

            // Actually, we can just ask isLoggedin() but it might not be ready.
            // A better pattern for AuthService would be to emit events or return a promise for init.

            // Let's optimize: We'll wait a tick.
            setTimeout(async () => {
                if (authService.isLoggedIn()) {
                    const currentUser = authService.getUser();
                    if (currentUser) {
                        try {
                            const response = await configService.getOnboarding();
                            if (response) {
                                currentUser.onboarding = response;
                            }
                        } catch (error) {
                            console.error('Failed to fetch onboarding status:', error);
                        }
                        setUser(currentUser);
                        setIsAuthenticated(true);
                    }
                }
                setIsLoading(false);
            }, 500);
        };
        checkAuth();
    }, []);

    const login = async (email: string, pass: string) => {
        setIsLoading(true);
        try {
            const user = await authService.login(email, pass);

            // Fetch onboarding status
            try {
                const response = await configService.getOnboarding();
                if (response) {
                    user.onboarding = response;
                }
            } catch (error) {
                console.error('Failed to fetch onboarding status:', error);
            }

            setUser(user);
            setIsAuthenticated(true);
        } finally {
            setIsLoading(false);
        }
    };

    const loginWithGoogle = async () => {
        await authService.signInWithWebBrowser();
    };

    const logout = () => {
        authService.logout();
        setUser(null);
        setIsAuthenticated(false);
    };

    const deleteAccount = async () => {
        await authService.deleteAccount();
        // logout logic is handled inside authService.deleteAccount, but let's clear state to be sure
        setUser(null);
        setIsAuthenticated(false);
    };

    const value = {
        user,
        isAuthenticated,
        login,
        loginWithGoogle,
        logout,
        deleteAccount,
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
