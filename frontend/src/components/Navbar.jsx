import React, { useState, useEffect } from 'react';
import { NavLink } from 'react-router-dom';
import TryButton from './ui/TryButton';
import './Navbar.css';

const Navbar = () => {
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

    const toggleMobileMenu = () => {
        setIsMobileMenuOpen(!isMobileMenuOpen);
    };

    const closeMobileMenu = () => {
        setIsMobileMenuOpen(false);
    };

    // Prevent body scroll when mobile menu is open
    useEffect(() => {
        if (isMobileMenuOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'unset';
        }
        return () => {
            document.body.style.overflow = 'unset';
        };
    }, [isMobileMenuOpen]);

    const navItems = [
        { path: '/', label: 'HOME' },
        { path: '/use-cases', label: 'USE CASES' },
        { path: '/pricing', label: 'PRICING' },
        { path: '/research', label: 'RESEARCH' },
    ];

    return (
        <nav className="navbar">
            <div className="navbar-container">
                <div className="navbar-left">
                    {/* Desktop Nav Links */}
                    <div className="nav-links">
                        {navItems.map((item) => (
                            <NavLink
                                key={item.path}
                                to={item.path}
                                className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}
                            >
                                {({ isActive }) => (
                                    <div className="nav-item">
                                        {isActive && <span className="dot"></span>}
                                        {item.label}
                                    </div>
                                )}
                            </NavLink>
                        ))}
                    </div>

                    {/* Mobile Hamburger Button */}
                    <button
                        className={`hamburger ${isMobileMenuOpen ? 'active' : ''}`}
                        onClick={toggleMobileMenu}
                        aria-label="Toggle menu"
                    >
                        <span className="bar"></span>
                        <span className="bar"></span>
                        <span className="bar"></span>
                    </button>
                </div>

                <div className="navbar-right">
                    <TryButton variant="outline" />
                </div>

                {/* Mobile Menu Overlay */}
                <div className={`mobile-menu ${isMobileMenuOpen ? 'open' : ''}`}>
                    <div className="mobile-nav-links">
                        {navItems.map((item) => (
                            <NavLink
                                key={item.path}
                                to={item.path}
                                className={({ isActive }) => isActive ? 'mobile-nav-link active' : 'mobile-nav-link'}
                                onClick={closeMobileMenu}
                            >
                                {item.label}
                            </NavLink>
                        ))}
                    </div>
                </div>
            </div>
        </nav>
    );
};

export default Navbar;
