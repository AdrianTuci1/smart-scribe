import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { drawThreeGeo } from '../utils/threeGeoJSON';

const GlobeThree = ({ isMobile }) => {
    const mountRef = useRef(null);

    useEffect(() => {
        const width = isMobile ? 600 : 1000;
        const height = isMobile ? 600 : 1000;

        // Scene setup
        const scene = new THREE.Scene();
        // Transparent background
        // Camera setup
        const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 1000);
        camera.position.z = 6;
        camera.position.y = 3;

        // Renderer setup
        const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
        renderer.setSize(width, height);
        renderer.setPixelRatio(window.devicePixelRatio);
        mountRef.current.appendChild(renderer.domElement);

        // Core Globe (wireframe/edges)
        const globeRadius = 2;
        const geometry = new THREE.SphereGeometry(globeRadius, 32, 32);

        // Sphere with subtle lines
        const lineMat = new THREE.LineBasicMaterial({
            color: 0x000000,
            transparent: true,
            opacity: 0.1
        });
        const edges = new THREE.EdgesGeometry(geometry, 1);
        const globeLines = new THREE.LineSegments(edges, lineMat);
        scene.add(globeLines);

        // Load GeoJSON
        fetch('/geojson/ne_110m_land.json')
            .then(res => res.json())
            .then(data => {
                const countries = drawThreeGeo({
                    json: data,
                    radius: globeRadius,
                    materialOptions: {
                        color: 0x000000,
                        linewidth: 1,
                        opacity: 1
                    }
                });
                scene.add(countries);
            });

        // Controls
        const controls = new OrbitControls(camera, renderer.domElement);
        controls.enableDamping = true;
        controls.dampingFactor = 0.05;
        controls.enableZoom = false; // Disable zoom to keep it consistent with UI
        controls.autoRotate = true;
        controls.autoRotateSpeed = 1.0;

        // Animation loop
        const animate = () => {
            requestAnimationFrame(animate);
            controls.update();
            renderer.render(scene, camera);
        };
        animate();

        // Cleanup
        return () => {
            if (mountRef.current) {
                mountRef.current.removeChild(renderer.domElement);
            }
            geometry.dispose();
            lineMat.dispose();
            edges.dispose();
            renderer.dispose();
        };
    }, [isMobile]);

    return (
        <div ref={mountRef} style={{ width: isMobile ? 600 : 1000, height: isMobile ? 600 : 1000 }} />
    );
};

export default GlobeThree;
