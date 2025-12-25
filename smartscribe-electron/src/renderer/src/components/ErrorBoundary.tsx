import React, { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
    children: ReactNode;
}

interface State {
    hasError: boolean;
    error: Error | null;
    errorInfo: ErrorInfo | null;
}

import './ErrorBoundary.css';

export class ErrorBoundary extends Component<Props, State> {
    public state: State = {
        hasError: false,
        error: null,
        errorInfo: null
    };

    public static getDerivedStateFromError(error: Error): State {
        return { hasError: true, error, errorInfo: null };
    }

    public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
        console.error('Uncaught error:', error, errorInfo);
        this.setState({ errorInfo });
    }

    public render() {
        if (this.state.hasError) {
            return (
                <div className="error-boundary-container">
                    <h1 className="error-title">Something went wrong</h1>
                    <h2 className="error-subtitle">Error:</h2>
                    <pre className="error-pre">
                        {this.state.error?.toString()}
                    </pre>
                    <h2 className="error-subtitle">Stack Trace:</h2>
                    <pre className="error-stack">
                        {this.state.errorInfo?.componentStack}
                    </pre>
                </div>
            );
        }

        return this.props.children;
    }
}
