import React from 'react';
import { useNavigate } from 'react-router-dom';
import './TryButton.css';

const TryButton = ({
    variant = 'outline', // 'outline' (Navbar) or 'outline-gray' (TargetUsers)
    className = '',
    children,
    onClick,
    ...props
}) => {
    const navigate = useNavigate();

    const handleClick = (e) => {
        if (onClick) onClick(e);
        navigate('/try-now');
    };

    return (
        <button
            className={`try-btn variant-${variant} ${className}`}
            onClick={handleClick}
            {...props}
        >
            <div className="btn-icon-orb"></div>
            <span>{children || 'Try Now'}</span>
        </button>
    );
};

export default TryButton;
