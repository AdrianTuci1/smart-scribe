import React from 'react';
import { LoginView } from '../Auth/LoginView';

interface LoginStepProps {
    onNext: () => void;
}

export const LoginStep: React.FC<LoginStepProps> = ({ onNext }) => {
    return (
        <LoginView onLoginSuccess={onNext} />
    );
};
