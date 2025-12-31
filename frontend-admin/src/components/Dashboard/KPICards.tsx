import React from 'react';
import type { LucideIcon } from 'lucide-react';
import '../../styles/variables.css';

interface MetricCardProps {
    label: string;
    value: React.ReactNode;
    icon?: LucideIcon;
    iconColor?: string;
    subtext?: React.ReactNode;
    subtitle?: string;
    className?: string; // For additional styling
}

export const MetricCard: React.FC<MetricCardProps> = ({ label, value, icon: Icon, iconColor, subtext, subtitle, className }) => {
    return (
        <div className={`floating-panel ${className || ''}`} style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: 6 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span className="label-sm">{label}</span>
                {Icon && <Icon size={16} color={iconColor || 'var(--text-primary)'} />}
            </div>

            <div style={{ fontSize: 32, fontWeight: 700, color: '#fff', letterSpacing: '-0.02em' }}>
                {value}
            </div>

            {(subtext || subtitle) && (
                <div style={{ fontSize: 11, color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: 4, marginTop: 4 }}>
                    {subtext || subtitle}
                </div>
            )}
        </div>
    );
};

// Keep the default export as a container if needed, or just export it as null if we don't need the composite anymore.
// But based on the request, we probably want to use MetricCard directly in App.tsx. 
// So let's just export MetricCard primarily.

const KPICards = () => {
    return null; // Deprecated in favor of direct MetricCard usage
};

export default KPICards;
