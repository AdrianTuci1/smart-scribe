import React from 'react';
import './DownloadButton.css';

const DownloadButton = ({
    variant = 'primary', // 'primary' (Hero) or 'secondary' (TargetUsers)
    className = '',
    children,
    onClick,
    ...props
}) => {
    const [os, setOs] = React.useState('macos');
    const [buttonText, setButtonText] = React.useState('Download for MacOS');
    const [isAvailable, setIsAvailable] = React.useState(true);
    const [downloadLink, setDownloadLink] = React.useState('');

    const comingSoonText = import.meta.env.VITE_COMING_SOON_TEXT || 'Available soon';

    React.useEffect(() => {
        const userAgent = window.navigator.userAgent.toLowerCase();
        let detectedOs = 'macos';
        let available = true;
        let link = '';
        let text = 'Download for MacOS';

        if (userAgent.indexOf('win') !== -1) {
            detectedOs = 'windows';
            available = import.meta.env.VITE_WINDOWS_AVAILABLE === 'true';
            link = import.meta.env.VITE_WINDOWS_DOWNLOAD_LINK || '';
            text = available ? 'Download for Windows' : comingSoonText;
        } else if (userAgent.indexOf('android') !== -1) {
            detectedOs = 'android';
            available = import.meta.env.VITE_ANDROID_AVAILABLE === 'true';
            link = import.meta.env.VITE_ANDROID_DOWNLOAD_LINK || '';
            text = available ? 'Download for Android' : comingSoonText;
        } else if (userAgent.indexOf('iphone') !== -1 || userAgent.indexOf('ipad') !== -1) {
            detectedOs = 'ios';
            available = import.meta.env.VITE_IOS_AVAILABLE === 'true';
            link = import.meta.env.VITE_IOS_DOWNLOAD_LINK || '';
            text = available ? 'Download for iOS' : comingSoonText;
        } else {
            // MacOS default
            detectedOs = 'macos';
            available = import.meta.env.VITE_MACOS_AVAILABLE !== 'false'; // Default to true if not set
            link = import.meta.env.VITE_MACOS_DOWNLOAD_LINK || '';
            text = available ? 'Download for MacOS' : comingSoonText;
        }

        setOs(detectedOs);
        setIsAvailable(available);
        setDownloadLink(link);
        setButtonText(text);
    }, [comingSoonText]);

    const getIcon = () => {
        if (os === 'macos' && isAvailable) {
            return (
                <svg
                    className="apple-icon"
                    viewBox="0 0 384 512"
                    width="20"
                    height="20"
                    fill="currentColor"
                >
                    <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z" />
                </svg>
            );
        }
        return null;
    };

    const handleDownload = (e) => {
        if (!isAvailable) return;

        if (os === 'macos') {
            if (onClick) onClick(e);
        } else if (downloadLink) {
            window.open(downloadLink, '_blank');
        }
    };

    return (
        <button
            className={`download-btn variant-${variant} ${className}`}
            onClick={handleDownload}
            disabled={!isAvailable}
            {...props}
            style={{ cursor: isAvailable ? 'pointer' : 'default', ...props.style }}
        >
            {getIcon()}
            <span>{children || buttonText}</span>
        </button>
    );
};

export default DownloadButton;
