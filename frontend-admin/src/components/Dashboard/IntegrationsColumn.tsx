import { useEffect, useState } from 'react';
import { Bot, Mail, Video, Globe2 } from 'lucide-react';
import '../../styles/variables.css';

const IntegrationsColumn = () => {
    // 1. Top Apps Data (for Single Line Bar)
    const apps = [
        { name: 'Slack', percent: 45, color: '#E01E5A', icon: Bot },
        { name: 'Zoom', percent: 30, color: '#2D8CFF', icon: Video },
        { name: 'Gmail', percent: 25, color: '#D44638', icon: Mail }
    ];

    // 2. Live Stream Data
    const [transcriptions, setTranscriptions] = useState([
        { id: 1, app: 'Slack', country: 'USA', time: '10:42:01' },
        { id: 2, app: 'Zoom', country: 'Germany', time: '10:42:05' },
        { id: 3, app: 'Notion', country: 'UK', time: '10:42:12' },
        { id: 4, app: 'Slack', country: 'Japan', time: '10:42:15' },
    ]);

    useEffect(() => {
        const interval = setInterval(() => {
            setTranscriptions(prev => {
                const newTx = {
                    id: Date.now(),
                    app: ['Slack', 'Zoom', 'Notion', 'Teams', 'Gmail'][Math.floor(Math.random() * 5)],
                    country: ['USA', 'UK', 'DE', 'JP', 'BR', 'RO'][Math.floor(Math.random() * 6)],
                    time: new Date().toLocaleTimeString()
                };
                return [newTx, ...prev].slice(0, 10); // Keep last 10
            });
        }, 2000);
        return () => clearInterval(interval);
    }, []);

    return (
        <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', gap: 20 }}>
            {/* Section 1: Top Apps Bar */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <h3 className="label-sm">Top Integrations Share</h3>
                <div style={{ width: '100%', height: 12, borderRadius: 6, overflow: 'hidden', display: 'flex', background: 'rgba(255,255,255,0.1)' }}>
                    {apps.map(app => (
                        <div key={app.name} style={{ width: `${app.percent}%`, background: app.color, height: '100%', position: 'relative' }} title={`${app.name} ${app.percent}%`}></div>
                    ))}
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    {apps.map(app => (
                        <div key={app.name} style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--text-secondary)' }}>
                            <div style={{ width: 6, height: 6, borderRadius: '50%', background: app.color }}></div>
                            {app.name} {app.percent}%
                        </div>
                    ))}
                </div>
            </div>

            {/* Section 2: Live Stream */}
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
                <h3 className="label-sm" style={{ marginBottom: 12 }}>Live Transcription Feed</h3>
                <div className="custom-scroll" style={{ overflowY: 'auto', flex: 1, paddingRight: 4 }}>
                    {transcriptions.map(tx => (
                        <div key={tx.id} style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            fontSize: 12,
                            padding: '8px 0',
                            borderBottom: '1px solid rgba(255,255,255,0.05)'
                        }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                <span style={{ color: 'var(--neon-cyan)', fontWeight: 600, width: 45 }}>{tx.app}</span>
                                <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--text-secondary)' }}>
                                    <Globe2 size={10} /> {tx.country}
                                </div>
                            </div>
                            <span style={{ fontFamily: 'monospace', color: 'var(--text-dim)', fontSize: 11 }}>{tx.time}</span>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default IntegrationsColumn;
