import { AlertTriangle } from 'lucide-react';

const riskUsers = [
    { id: 1, name: 'Alice Freeman', words: 154200, expires: '2 Days' },
    { id: 2, name: 'Bob Smith', words: 120500, expires: '1 Day' },
    { id: 3, name: 'Charlie Davis', words: 98000, expires: '5 Hours' },
    { id: 4, name: 'Diana Prince', words: 85000, expires: '3 Days' },
    { id: 5, name: 'Evan Wright', words: 72000, expires: '12 Hours' },
];

const SubscriptionRiskList = () => {
    return (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {riskUsers.map((user, index) => (
                <div key={user.id} style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '6px 0',
                    borderBottom: index < riskUsers.length - 1 ? '1px solid rgba(255,255,255,0.05)' : 'none'
                }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <span style={{
                            fontSize: 11,
                            color: 'var(--text-muted)',
                            width: 16
                        }}>{index + 1}</span>
                        <div style={{
                            width: 28,
                            height: 28,
                            borderRadius: '50%',
                            background: 'rgba(255,255,255,0.08)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: 11,
                            fontWeight: 500,
                            color: 'var(--text-secondary)'
                        }}>
                            {user.name.charAt(0)}
                        </div>
                        <div>
                            <div style={{ fontSize: 13, fontWeight: 500 }}>{user.name}</div>
                            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{user.words.toLocaleString()} words</div>
                        </div>
                    </div>

                    <div style={{
                        fontSize: 11,
                        color: 'var(--neon-red)',
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4
                    }}>
                        <AlertTriangle size={10} />
                        {user.expires}
                    </div>
                </div>
            ))}
        </div>
    );
};

export default SubscriptionRiskList;
