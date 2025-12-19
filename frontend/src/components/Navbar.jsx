import React from 'react';
import { NavLink } from 'react-router-dom';
import './Navbar.css';

const Navbar = () => {
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
                </div>

                <div className="navbar-right">
                    <button className="try-now-btn">
                        <div className="btn-icon"></div>
                        <span>Try Now</span>
                    </button>
                </div>
            </div>
        </nav>
    );
};

export default Navbar;
