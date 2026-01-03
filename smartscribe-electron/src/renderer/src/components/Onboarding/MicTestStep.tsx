import React, { useEffect, useRef, useState } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import './MicTestStep.css';

interface MicTestStepProps {
    onNext: () => void;
    onBack: () => void;
    visualImage?: string;
}

export const MicTestStep: React.FC<MicTestStepProps> = ({ onNext, onBack, visualImage }) => {
    const canvasRef = useRef<HTMLCanvasElement>(null); // Optional if using canvas, but sticking to DOM bars for simplicity of React state or just CSS anims
    const [audioContext, setAudioContext] = useState<AudioContext | null>(null);
    const [analyser, setAnalyser] = useState<AnalyserNode | null>(null);
    const [dataArray, setDataArray] = useState<Uint8Array | null>(null);
    const [volumes, setVolumes] = useState<number[]>(new Array(10).fill(0)); // 10 bars
    const requestRef = useRef<number | null>(null);

    useEffect(() => {
        const initAudio = async () => {
            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
                const analyserNode = audioCtx.createAnalyser();
                analyserNode.fftSize = 64; // Small size for fewer bars
                const source = audioCtx.createMediaStreamSource(stream);
                source.connect(analyserNode);

                setAudioContext(audioCtx);
                setAnalyser(analyserNode);
                const bufferLength = analyserNode.frequencyBinCount;
                setDataArray(new Uint8Array(bufferLength));
            } catch (err) {
                console.error("Error accessing microphone:", err);
            }
        };

        initAudio();

        return () => {
            if (audioContext) audioContext.close();
            if (requestRef.current !== null) cancelAnimationFrame(requestRef.current);
        };
    }, []);

    const animate = () => {
        if (analyser && dataArray) {
            analyser.getByteFrequencyData(dataArray as any);

            // Map data to 10 bars
            // dataArray length is 32 (half of 64)
            // We want 10 values. Simple sampling.
            const newVolumes: number[] = [];
            const step = Math.floor(dataArray.length / 10);
            for (let i = 0; i < 10; i++) {
                const value = dataArray[i * step];
                newVolumes.push(value);
            }
            setVolumes(newVolumes);
        }
        requestRef.current = requestAnimationFrame(animate);
    };

    useEffect(() => {
        if (analyser) {
            requestRef.current = requestAnimationFrame(animate);
        }
    }, [analyser]);

    const VisualizerCard = (
        <div className="mic-visual-card">
            <h3 className="mic-card-title">Do you see purple bars moving while you speak?</h3>

            <div className="visualizer-container">
                {volumes.map((vol, idx) => {
                    // normalize vol 0-255 to height % or similar
                    // Let's make it simple: min height 20%, max 100%
                    const percent = Math.max(20, (vol / 255) * 100);
                    const isActive = vol > 10;
                    return (
                        <div
                            key={idx}
                            className={`visualizer-bar ${isActive ? 'active' : ''}`}
                            style={{ height: `${percent}%` }}
                        />
                    );
                })}
            </div>

            <div className="mic-actions">
                <button className="change-mic-button">No, change microphone</button>
                <button className="confirm-mic-button" onClick={onNext}>Yes</button>
            </div>
        </div>
    );

    return (
        <OnboardingLayout
            currentStep={5}
            totalSteps={8}
            showVisual={true}
            visualContent={VisualizerCard}
            visualImage={visualImage}
        >
            <div className="mic-test-container">
                <button
                    className="back-button-simple"
                    onClick={onBack}
                    style={{
                        alignSelf: 'flex-start',
                        background: 'none',
                        border: 'none',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        color: '#6b7280',
                        cursor: 'pointer',
                        marginBottom: '24px',
                        fontSize: '14px'
                    }}
                >
                    ← Back
                </button>

                <h1 className="mic-test-title">Speak to test your microphone</h1>
                <p className="mic-test-subtitle">
                    Your computer's built-in mic will ensure optimal transcription.
                </p>

                {/* Visualizer is passed to the right side via visualContent */}
            </div>
        </OnboardingLayout>
    );
};
