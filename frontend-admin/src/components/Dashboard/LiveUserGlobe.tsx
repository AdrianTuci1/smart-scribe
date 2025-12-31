import { useEffect, useRef, useState } from 'react';
import Globe from 'react-globe.gl';
import { useResizeDetector } from 'react-resize-detector';

interface UserData {
    lat: number;
    lng: number;
    city: string;
    time: string;
    avatarUrl: string;
}

const LiveUserGlobe = () => {
    const globeEl = useRef<any>(null);
    const [users, setUsers] = useState<UserData[]>([]);
    const { width, height, ref } = useResizeDetector();

    useEffect(() => {
        // Generate mock data representing users from last 10 minutes
        const mockUsers = Array.from({ length: 30 }).map(() => ({
            lat: (Math.random() - 0.5) * 160,
            lng: (Math.random() - 0.5) * 360,
            city: ['New York', 'London', 'Berlin', 'Tokyo', 'Sydney', 'Paris', 'Bucharest'][Math.floor(Math.random() * 7)],
            time: new Date(Date.now() - Math.random() * 600000).toLocaleTimeString(),
            avatarUrl: `https://i.pravatar.cc/150?u=${Math.random()}`
        }));
        setUsers(mockUsers);

        // Auto-rotate
        setTimeout(() => {
            if (globeEl.current) {
                globeEl.current.controls().autoRotate = true;
                globeEl.current.controls().autoRotateSpeed = 0.5;
                globeEl.current.pointOfView({ lat: 20, lng: 0, altitude: 2.5 });
            }
        }, 100);
    }, []);

    return (
        <div ref={ref} style={{
            width: '100%',
            height: '100%',
            position: 'relative',
            background: 'radial-gradient(circle at 50% 50%, #08081a 0%, #000 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            overflow: 'hidden'
        }}>
            {width && (
                <Globe
                    ref={globeEl}
                    width={width}
                    height={height}
                    globeImageUrl="//unpkg.com/three-globe/example/img/earth-night.jpg"
                    backgroundImageUrl="//unpkg.com/three-globe/example/img/night-sky.png"
                    atmosphereColor="rgba(0, 100, 255, 0.6)"
                    atmosphereAltitude={0.25}

                    htmlElementsData={users}
                    htmlLat={d => (d as UserData).lat}
                    htmlLng={d => (d as UserData).lng}
                    htmlElement={d => {
                        const el = document.createElement('div');
                        const user = d as UserData;
                        el.style.display = 'flex';
                        el.style.flexDirection = 'column';
                        el.style.alignItems = 'center';
                        el.style.transform = 'translate(-50%, -100%)';
                        el.style.pointerEvents = 'none'; // Prevent blocking interactions

                        el.innerHTML = `
              <div style="
                width: 24px; 
                height: 24px; 
                background: url(${user.avatarUrl}); 
                background-size: cover; 
                border-radius: 50%; 
                border: 2px solid #00f3ff;
                box-shadow: 0 0 10px #00f3ff;
                position: relative;
              "></div>
              <div style="
                width: 2px;
                height: 10px;
                background: linear-gradient(to bottom, #00f3ff, transparent);
              "></div>
            `;
                        return el;
                    }}
                />
            )}
            <div style={{ position: 'absolute', top: 40, left: '50%', transform: 'translateX(-50%)', textAlign: 'center', pointerEvents: 'none' }}>
                <h3 className="neon-text-cyan" style={{ fontSize: 24, letterSpacing: 4, textTransform: 'uppercase' }}>Smartscribe <span style={{ color: '#fff' }}>Live</span></h3>
                <p className="label-sm">Global User Activity</p>
            </div>
        </div>
    );
};

export default LiveUserGlobe;
