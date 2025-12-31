import { Activity } from 'lucide-react';
import '../../styles/variables.css';

const SystemLoadWidget = () => {
    return (
        <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 8 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <Activity size={18} color="var(--neon-green)" />
                    <span className="label-sm" style={{ fontSize: 13 }}>System Load</span>
                </div>
                <span style={{ fontSize: 20, fontWeight: 700, color: 'var(--neon-green)' }}>42%</span>
            </div>

            {/* Load Line segment */}
            <div style={{ width: '100%', height: 8, background: 'rgba(255,255,255,0.1)', borderRadius: 4, overflow: 'hidden', display: 'flex' }}>
                <div style={{ width: '42%', background: 'var(--neon-green)', height: '100%', boxShadow: '0 0 10px var(--neon-green)' }} title="Active"></div>
                <div style={{ width: '20%', background: '#ffcc00', height: '100%' }} title="Moderate"></div>
                <div style={{ width: '10%', background: 'var(--neon-red)', height: '100%' }} title="Heavy"></div>
                <div style={{ flex: 1, background: 'transparent' }} title="Idle"></div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
                <span style={{ fontSize: 10, color: 'var(--text-secondary)' }}>Server: eu-central-1</span>
                <span style={{ fontSize: 10, color: 'var(--text-secondary)' }}>Capacity: Optimal</span>
            </div>
        </div>
    );
};

export default SystemLoadWidget;
