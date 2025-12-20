import React, { useEffect, useRef, useState } from 'react';
import createGlobe from 'cobe';

const Globe = ({ className = '' }) => {
    const canvasRef = useRef();
    const containerRef = useRef();
    const pointerInteracting = useRef(null);
    const pointerInteractionMovement = useRef(0);
    const [rotation, setRotation] = useState([0, 0]);

    useEffect(() => {
        let phi = 0;
        let theta = 0.3;
        let width = 0;
        let targetRotation = [0, 0];
        let currentRotation = [0, 0];

        const onResize = () => canvasRef.current && (width = canvasRef.current.offsetWidth);
        window.addEventListener('resize', onResize);
        onResize();

        const globe = createGlobe(canvasRef.current, {
            devicePixelRatio: 2,
            width: width * 2,
            height: width * 2,
            phi: 0,
            theta: 0.3,
            dark: 0,
            diffuse: 1.2,
            mapSamples: 16000,
            mapBrightness: 6,
            baseColor: [0.3, 0.3, 0.3],
            markerColor: [0.1, 0.4, 1],
            glowColor: [1, 1, 1],
            markers: [
                { location: [37.7595, -122.4367], size: 0.03 },
                { location: [40.7128, -74.006], size: 0.03 },
                { location: [51.5074, -0.1278], size: 0.03 },
                { location: [35.6762, 139.6503], size: 0.03 },
                { location: [48.8566, 2.3522], size: 0.03 },
                { location: [-33.8688, 151.2093], size: 0.03 },
            ],
            onRender: (state) => {
                // Very slow auto-rotation
                if (!pointerInteracting.current) {
                    phi += 0.002;
                }

                // Smooth interpolation for fluid movement
                targetRotation = rotation;
                currentRotation[0] += (targetRotation[0] - currentRotation[0]) * 0.1;
                currentRotation[1] += (targetRotation[1] - currentRotation[1]) * 0.1;

                // Apply rotation from mouse movement and drag
                state.phi = phi + currentRotation[0];
                state.theta = theta + currentRotation[1];

                state.width = width * 2;
                state.height = width * 2;
            }
        });

        // Mouse movement influence
        const onMouseMove = (e) => {
            if (canvasRef.current && pointerInteracting.current !== null) {
                const delta = e.clientX - pointerInteracting.current;
                pointerInteractionMovement.current = delta;
                setRotation([delta / 100, 0]);
            }
        };

        const onMouseDown = (e) => {
            pointerInteracting.current = e.clientX - pointerInteractionMovement.current;
        };

        const onMouseUp = () => {
            pointerInteracting.current = null;
        };

        const onPointerMove = (e) => {
            if (containerRef.current && !pointerInteracting.current) {
                const rect = containerRef.current.getBoundingClientRect();
                const x = (e.clientX - rect.left) / rect.width - 0.5;
                const y = (e.clientY - rect.top) / rect.height - 0.5;
                // Inverted x-axis and stronger influence
                setRotation([-x * 1.5, -y * 0.8]);
            }
        };

        const container = containerRef.current;
        container.addEventListener('mousemove', onPointerMove);
        container.addEventListener('mousedown', onMouseDown);
        window.addEventListener('mouseup', onMouseUp);
        window.addEventListener('mousemove', onMouseMove);

        return () => {
            globe.destroy();
            window.removeEventListener('resize', onResize);
            container.removeEventListener('mousemove', onPointerMove);
            container.removeEventListener('mousedown', onMouseDown);
            window.removeEventListener('mouseup', onMouseUp);
            window.removeEventListener('mousemove', onMouseMove);
        };
    }, [rotation]);

    return (
        <div
            ref={containerRef}
            className={className}
            style={{
                width: '100%',
                height: '100%',
            }}
        >
            <canvas
                ref={canvasRef}
                style={{
                    width: '100%',
                    height: '100%',
                    maxWidth: '100%',
                    aspectRatio: '1',
                    cursor: pointerInteracting.current !== null ? 'grabbing' : 'grab',
                    background: 'transparent',
                }}
            />
        </div>
    );
};

export default Globe;
