import { Tooltip } from 'react-tooltip';
import '../../styles/variables.css';

const ActivityHeatmap = () => {
    // Generate mock data: 52 weeks x 7 days
    const weeks = 20; // Show last 20 weeks to fit nicely
    const days = 7;

    const getIntensity = () => {
        const rand = Math.random();
        if (rand > 0.9) return 4; // High
        if (rand > 0.7) return 3;
        if (rand > 0.5) return 2;
        if (rand > 0.2) return 1;
        return 0; // None
    };

    const getColor = (level: number) => {
        switch (level) {
            case 0: return 'rgba(255, 255, 255, 0.05)';
            case 1: return 'rgba(0, 243, 255, 0.2)';
            case 2: return 'rgba(0, 243, 255, 0.5)';
            case 3: return 'rgba(0, 243, 255, 0.8)';
            case 4: return 'var(--neon-cyan)';
            default: return 'rgba(255, 255, 255, 0.05)';
        }
    };

    const grid = Array.from({ length: weeks }).map(() =>
        Array.from({ length: days }).map(() => ({
            level: getIntensity(),
            date: new Date().toDateString() // Mock date
        }))
    );

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return (
        <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
            <div style={{
                display: 'flex',
                gap: 3,
                flex: 1,
                alignItems: 'stretch'
            }}>
                {/* Day labels column */}
                <div style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 2,
                    justifyContent: 'space-between',
                    paddingRight: 6
                }}>
                    {dayLabels.map(day => (
                        <div key={day} style={{
                            flex: 1,
                            display: 'flex',
                            alignItems: 'center',
                            fontSize: 9,
                            color: 'var(--text-muted)',
                            minHeight: 6,
                            maxHeight: 10
                        }}>
                            {day}
                        </div>
                    ))}
                </div>

                {/* Heatmap grid */}
                {grid.map((week, wIndex) => (
                    <div key={wIndex} style={{
                        display: 'flex',
                        flexDirection: 'column',
                        gap: 2,
                        flex: 1
                    }}>
                        {week.map((day, dIndex) => (
                            <div
                                key={dIndex}
                                data-tooltip-id="heatmap-tooltip"
                                data-tooltip-content={`${dayLabels[dIndex]}: Activity Level ${day.level}`}
                                style={{
                                    flex: 1,
                                    minHeight: 6,
                                    maxHeight: 10,
                                    borderRadius: 1,
                                    backgroundColor: getColor(day.level),
                                    transition: 'all 0.2s ease'
                                }}
                            />
                        ))}
                    </div>
                ))}
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 8, color: 'var(--text-muted)', fontSize: 10, gap: 8, alignItems: 'center' }}>
                <span>Less</span>
                <div style={{ display: 'flex', gap: 2 }}>
                    {[0, 1, 2, 3, 4].map(l => (
                        <div key={l} style={{ width: 10, height: 10, borderRadius: 1, backgroundColor: getColor(l) }} />
                    ))}
                </div>
                <span>More</span>
            </div>
            <Tooltip id="heatmap-tooltip" style={{ backgroundColor: 'var(--bg-deep)', color: '#fff', borderRadius: 4 }} />
        </div>
    );
};

export default ActivityHeatmap;
