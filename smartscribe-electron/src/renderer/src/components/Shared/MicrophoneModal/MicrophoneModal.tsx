import React, { useEffect, useState } from 'react';
import { X, Mic } from 'lucide-react';
import { configService } from '../../../services/api/config';
import './MicrophoneModal.css';

interface MicrophoneModalProps {
    isOpen: boolean;
    onClose: () => void;
}

interface AudioDevice {
    deviceId: string;
    label: string;
}

export const MicrophoneModal: React.FC<MicrophoneModalProps> = ({ isOpen, onClose }) => {
    const [devices, setDevices] = useState<AudioDevice[]>([]);
    const [selectedMic, setSelectedMic] = useState<string>('Auto Detect');

    useEffect(() => {
        if (isOpen) {
            loadSettings();
            loadDevices();
        }
    }, [isOpen]);

    const loadSettings = async () => {
        try {
            const settings = await configService.getSettings();
            if (settings.selectedMicrophone) {
                setSelectedMic(settings.selectedMicrophone);
            }
        } catch (error) {
            console.error('Failed to load settings:', error);
        }
    };

    const loadDevices = async () => {
        try {
            await navigator.mediaDevices.getUserMedia({ audio: true });
            const allDevices = await navigator.mediaDevices.enumerateDevices();
            const audioInputs = allDevices
                .filter(device => device.kind === 'audioinput')
                .map(device => ({
                    deviceId: device.deviceId,
                    label: device.label || `Microphone ${device.deviceId.slice(0, 5)}...`
                }));
            setDevices(audioInputs);
        } catch (error) {
            console.error('Failed to load audio devices:', error);
        }
    };

    const handleMicChange = async (deviceId: string) => {
        setSelectedMic(deviceId);
        try {
            await configService.updateSettings({ selectedMicrophone: deviceId });
        } catch (error) {
            console.error('Failed to save microphone setting:', error);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="mic-modal-overlay" onClick={onClose}>
            <div className="mic-modal" onClick={e => e.stopPropagation()}>
                <div className="mic-modal-header">
                    <h2>Microphone</h2>
                    <button className="close-button" onClick={onClose}>
                        <X size={20} />
                    </button>
                </div>

                <div className="mic-modal-content">
                    {/* Auto Detect Option */}
                    <div
                        className={`mic-option ${selectedMic === 'Auto Detect' ? 'selected' : ''}`}
                        onClick={() => handleMicChange('Auto Detect')}
                    >
                        <div className="mic-info">
                            <h3>Auto-detect (System Default)</h3>
                            <p>Overrides other mics when connected</p>
                        </div>
                    </div>

                    {/* Device List */}
                    {devices.map(device => (
                        <div
                            key={device.deviceId}
                            className={`mic-option ${selectedMic === device.deviceId ? 'selected' : ''}`}
                            onClick={() => handleMicChange(device.deviceId)}
                        >
                            <div className="mic-info">
                                <h3>{device.label}</h3>
                            </div>
                            {selectedMic === device.deviceId && (
                                <div className="mic-visualizer-icon">
                                    {/* Placeholder for visualizer lines if needed */}
                                    <div className="visual-bar"></div>
                                    <div className="visual-bar"></div>
                                    <div className="visual-bar"></div>
                                    <div className="visual-bar"></div>
                                    <div className="visual-bar"></div>
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};
