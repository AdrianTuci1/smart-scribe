import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import './AuthModal.css';

const AuthModal = ({ isOpen, onClose }) => {
    const [isLogin, setIsLogin] = useState(true);
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const { login, loginWithGoogle } = useAuth();
    const [isLoading, setIsLoading] = useState(false);

    if (!isOpen) return null;

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            if (isLogin) {
                await login(email, password);
                onClose();
            } else {
                // For this implementation, we might redirect to a signup page or 
                // handle signup via Cognito if supported directly in this modal.
                // Given the requirement "sign in... or continuing with google", 
                // focus on Login. Signup is often a separate flow or unified.
                // Let's assume login for now or generic "auth" handling.
                // If signup is needed, we'd add checks. 
                // But the user prompt specificied "sign in ... or continue with google".
                // We'll treat email/pass as Login.
                // If user doesn't exist, Cognito might throw UserNotFound.
                await login(email, password);
                onClose();
            }
        } catch (err) {
            console.error(err);
            setError(err.message || 'Authentication failed');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="auth-modal-overlay">
            <div className="auth-modal-content">
                <button className="close-button" onClick={onClose}>&times;</button>
                <h2>{isLogin ? 'Welcome Back' : 'Get Started'}</h2>
                <p className="auth-subtitle">Sign in to SmartScribe to continue</p>

                {error && <div className="auth-error">{error}</div>}

                <button
                    className="google-auth-button"
                    onClick={loginWithGoogle}
                    type="button"
                >
                    <svg className="google-icon" viewBox="0 0 24 24">
                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
                    </svg>
                    Continue with Google
                </button>

                <div className="auth-divider">
                    <span>or</span>
                </div>

                <form onSubmit={handleSubmit}>
                    <div className="form-group">
                        <label>Email</label>
                        <input
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            placeholder="name@example.com"
                        />
                    </div>
                    <div className="form-group">
                        <label>Password</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            placeholder="••••••••"
                        />
                    </div>
                    <button type="submit" className="auth-submit-button" disabled={isLoading}>
                        {isLoading ? 'Signing in...' : 'Sign In'}
                    </button>
                </form>

                <div className="auth-footer">
                    <p>
                        Don't have an account?{' '}
                        <button className="link-button" onClick={() => setIsLogin(!isLogin)} type="button">
                            {isLogin ? 'Sign up (Web)' : 'Login'}
                        </button>
                        <span style={{ fontSize: '0.8em', display: 'block', marginTop: '5px', color: '#666' }}>
                            (Note: Signup typically redirects to App or creates new account)
                        </span>
                    </p>
                </div>
            </div>
        </div>
    );
};

export default AuthModal;
