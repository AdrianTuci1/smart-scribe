import React, { useEffect, useRef } from 'react';
import createGlobe from 'cobe';

const Globe = ({ className = '' }) => {
    const canvasRef = useRef();
    const containerRef = useRef();


    useEffect(() => {
        let phi = 0;
        let theta = 0.3;
        let width = 0;


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
            mapBrightness: 1,
            baseColor: [1, 1, 1, 0],
            markerColor: [0.1, 0.4, 1],
            glowColor: [1, 1, 1, 0],
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
                phi += 0.002;

                // Apply rotation
                state.phi = phi;
                state.theta = theta;

                state.width = width * 2;
                state.height = width * 2;
            }
        });

        return () => {
            globe.destroy();
            window.removeEventListener('resize', onResize);
        };
    }, []);

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
                    cursor: 'default',
                    background: 'transparent',
                }}
            />
        </div>
    );
};

export default Globe;
