import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { ChevronRight, Search, Home, Inbox, ListTodo, Users, Map, Globe, HelpCircle, ArrowLeft } from 'lucide-react';
import loginBg from '../../assets/login-bg.png';
import { TicketModal } from '../Shared/TicketModal';
import './LoginView.css';

export const LoginView = ({ onLoginSuccess }: { onLoginSuccess: () => void }) => {
    const { login, loginWithGoogle, isLoading: authLoading } = useAuth();
    const [loginStep, setLoginStep] = useState<'email' | 'password'>('email');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [showTicketModal, setShowTicketModal] = useState(false);

    const handleEmailSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);
        if (!email.trim()) {
            setError('Please enter your email.');
            return;
        }
        // Ideally check if email exists here, but for now just move to password step
        setLoginStep('password');
    };

    const handlePasswordSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);
        setIsSubmitting(true);
        try {
            await login(email, password);
            onLoginSuccess();
        } catch (err: any) {
            console.error(err);
            setError(err.message || 'Login failed');
            setIsSubmitting(false);
        }
    };

    const handleBackToEmail = () => {
        setLoginStep('email');
        setError(null);
        setPassword('');
    };

    const handleSSO = async () => {
        try {
            await loginWithGoogle();
        } catch (error) {
            console.error("SSO Error:", error);
        }
    };

    const steps = ['SIGN IN', 'PERMISSIONS', 'SET UP', 'LEARN'];
    const currentStepIndex = 0;

    return (
        <div className="login-view-container">
            {/* Header / Breadcrumbs */}
            <div className="login-header">
                <div className="breadcrumbs">
                    {steps.map((step, index) => (
                        <React.Fragment key={step}>
                            <div className={`crumb-item ${index === currentStepIndex ? 'active' : ''}`}>
                                <span className={`crumb-text ${index > currentStepIndex ? 'future' : ''}`}>{step}</span>
                            </div>
                            {index < steps.length - 1 && (
                                <ChevronRight className="crumb-separator" size={12} />
                            )}
                        </React.Fragment>
                    ))}
                </div>
            </div>

            {/* Left Side - Form */}
            <div className="login-form-section">
                <div className="login-form-content">
                    {/* Logo */}
                    <div className="brand-section">
                        <div className="brand-logo">
                            <div className="logo-icon">ll</div>
                            <span>Flow</span>
                        </div>
                    </div>

                    <h1 className="section-title">Get started with Flow</h1>
                    <p className="section-subtitle">Write faster in every app using your voice.</p>

                    {/* SSO Buttons - Only show on Email step? Usually yes. */}
                    {loginStep === 'email' && (
                        <div className="sso-grid">
                            <button onClick={handleSSO} className="sso-button">
                                <span className="sso-icon">G</span> Google
                            </button>
                            <button onClick={handleSSO} className="sso-button">
                                <span className="sso-icon">M</span> Microsoft
                            </button>
                            <button onClick={handleSSO} className="sso-button">
                                <span className="sso-icon"></span> Apple
                            </button>
                            <button onClick={handleSSO} className="sso-button">
                                <div className="sso-icon"><Globe size={16} /></div> SSO
                            </button>
                        </div>
                    )}

                    {/* Error Message */}
                    {error && <div style={{ color: 'red', marginTop: '10px', fontSize: '14px' }}>{error}</div>}

                    {loginStep === 'email' && (
                        <div className="divider-wrapper">
                            <div className="divider-line"></div>
                            <span className="divider-text">OR</span>
                        </div>
                    )}

                    {/* Email Form */}
                    {loginStep === 'email' ? (
                        <form onSubmit={handleEmailSubmit} className="email-form">
                            <input
                                type="email"
                                placeholder="Enter an email address"
                                className="email-input"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                                autoFocus
                            />
                            <p className="form-hint">
                                Use your school or work email to access team features
                            </p>
                            <button
                                type="submit"
                                className="submit-button"
                            >
                                Continue with Email
                            </button>
                        </form>
                    ) : (
                        <form onSubmit={handlePasswordSubmit} className="email-form">
                            <div className="email-display-group" style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <button type="button" onClick={handleBackToEmail} className="back-to-email-btn" style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '4px' }}>
                                    <ArrowLeft size={16} color="#6b7280" />
                                </button>
                                <span style={{ fontSize: '14px', color: '#374151', fontWeight: 500 }}>{email}</span>
                            </div>

                            <input
                                type="password"
                                placeholder="Enter your password"
                                className="email-input"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                                autoFocus
                            />

                            <button
                                type="submit"
                                disabled={isSubmitting || authLoading}
                                className="submit-button"
                                style={{ marginTop: '16px' }}
                            >
                                {isSubmitting || authLoading ? 'Logging in...' : 'Log in'}
                            </button>

                            <button
                                type="button"
                                onClick={handleBackToEmail}
                                style={{
                                    marginTop: '12px',
                                    background: 'none',
                                    border: 'none',
                                    color: '#6b7280',
                                    cursor: 'pointer',
                                    fontSize: '13px',
                                    width: '100%'
                                }}
                            >
                                Use a different email
                            </button>
                        </form>
                    )}

                    {loginStep === 'email' && (
                        <p className="legal-text">
                            By signing up, you agree to our <a href="#" className="legal-link">Terms of Service</a> and <a href="#" className="legal-link">Privacy Policy</a>.
                        </p>
                    )}
                </div>

                <div className="help-container">
                    <button className="help-button" onClick={() => setShowTicketModal(true)}>
                        <HelpCircle size={14} /> Help
                    </button>
                    {/* Removed Skip (Dev) button */}
                </div>
            </div>

            {/* Right Side - Visual */}
            <div className="login-visual-section">
                {/* Background Image Effect */}
                <img
                    src={loginBg}
                    alt="Background"
                    className="visual-background-image"
                />
                <div className="visual-overlay"></div>


                {/* Featured Card (Flowin Workspace) */}
                <div className="feature-card">
                    {/* Sidebar */}
                    <div className="card-sidebar">
                        <div className="workspace-header">
                            <div className="workspace-icon">F</div>
                            <span className="workspace-name">Flowin Workspace</span>
                        </div>
                        <div className="sidebar-menu">
                            <div className="menu-item"><Home size={14} /> Home</div>
                            <div className="menu-item"><Search size={14} /> Search</div>
                            <div className="menu-item"><Inbox size={14} /> Inbox</div>
                        </div>
                        <div>
                            <div className="favorites-header">Favorites</div>
                            <div className="sidebar-menu">
                                <div className="menu-item active">
                                    <span>✨</span> Crazy product ideas
                                </div>
                                <div className="menu-item">
                                    <ListTodo size={14} style={{ color: '#22c55e' }} /> My to dos
                                </div>
                                <div className="menu-item">
                                    <Users size={14} /> Freelancers
                                </div>
                                <div className="menu-item">
                                    <Map size={14} /> Roadmap
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Content */}
                    <div className="card-content">
                        <div className="content-header">
                            <span style={{ color: '#facc15', fontSize: '20px' }}>✨</span>
                            <h2 className="content-title">Crazy product ideas</h2>
                        </div>

                        <div className="product-list">
                            <div>
                                <h3 className="product-category">Physical Products</h3>
                                <div className="product-list">
                                    <div className="product-item">
                                        <b className="product-name">Self-Watering Plant Shoes</b>
                                        Sneakers with built-in planters and a tiny water reservoir. Walk, water, grow!
                                    </div>
                                    <div className="product-item">
                                        <b className="product-name">Mood Color Changing Wallpaper</b>
                                        Smart wallpaper that shifts color based on your mood (sensed via wearable or app)
                                    </div>
                                    <div className="product-item">
                                        <b className="product-name">Portable Nap Pod Backpack</b>
                                        Backpack unfolds into a private, soundproof nap cocoon. For airports, parks, anywhere!
                                    </div>
                                    <div className="product-item">
                                        <b className="product-name">Pet Translator Collar</b>
                                        Collar for dogs/cats that translates barks/meows into human speech.
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="visual-footer">

                    <h2 className="feature-title">Works in any app</h2>
                    <div className="pagination-dots">
                        <div className="dot active"></div>
                        <div className="dot" style={{ opacity: 0.4 }}></div>
                        <div className="dot" style={{ opacity: 0.4 }}></div>
                        <div className="dot" style={{ opacity: 0.4 }}></div>
                    </div>
                </div>

                {/* Scroll/Progress Bar */}
                <div className="scroll-indicator">
                    <div className="scroll-progress"></div>
                </div>
            </div>

            {/* Ticket Modal */}
            <TicketModal
                isOpen={showTicketModal}
                onClose={() => setShowTicketModal(false)}
                prefillEmail={email}
            />
        </div>
    );
};
