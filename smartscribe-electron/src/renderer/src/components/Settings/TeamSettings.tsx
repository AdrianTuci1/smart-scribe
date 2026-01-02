import React, { useState, useEffect } from 'react';
import { Users, Send, Check } from 'lucide-react';
import { SettingsTabProps } from './types';
import { teamService } from '../../services/api';

export const TeamSettings: React.FC<SettingsTabProps> = () => {
    const [emails, setEmails] = useState(['', '', '']);
    const [isLoading, setIsLoading] = useState(false);
    const [members, setMembers] = useState<any[]>([]);
    const [inviteStatus, setInviteStatus] = useState<'idle' | 'success' | 'error'>('idle');

    useEffect(() => {
        loadMembers();
    }, []);

    const loadMembers = async () => {
        try {
            const res = await teamService.getMembers() as any;
            if (res && res.members) {
                setMembers(res.members);
            }
        } catch (e) {
            console.error("Failed to load team members", e);
        }
    };

    const handleInvite = async () => {
        const validEmails = emails.filter(e => e && e.includes('@'));
        if (validEmails.length === 0) return;

        setIsLoading(true);
        try {
            // Sequential invites for MVP
            for (const email of validEmails) {
                await teamService.inviteMember(email);
            }
            setInviteStatus('success');
            setTimeout(() => setInviteStatus('idle'), 3000);
            setEmails(['', '', '']);
            loadMembers();
        } catch (e) {
            console.error(e);
            setInviteStatus('error');
        } finally {
            setIsLoading(false);
        }
    };

    const updateEmail = (index: number, val: string) => {
        const newEmails = [...emails];
        newEmails[index] = val;
        setEmails(newEmails);
    };

    return (
        <>
            <div className="settings-section">
                <h3 className="settings-section-title">Invite Your Teammates</h3>
                <div className="settings-card">
                    {emails.map((email, i) => (
                        <div className="settings-row" key={i}>
                            <span className="row-label" style={{ width: '80px' }}>Email {i + 1}</span>
                            <input
                                type="email"
                                className="settings-input"
                                placeholder="Enter email address"
                                value={email}
                                onChange={(e) => updateEmail(i, e.target.value)}
                            />
                        </div>
                    ))}

                    <div style={{ padding: '16px', display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: '10px' }}>
                        {inviteStatus === 'success' && <span style={{ color: '#4ade80', display: 'flex', alignItems: 'center', gap: '5px' }}><Check size={16} /> Invites Sent!</span>}
                        <button
                            className="primary-btn"
                            onClick={handleInvite}
                            disabled={isLoading || !emails.some(e => e)}
                            style={{ background: '#3b82f6', color: 'white', border: 'none', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' }}
                        >
                            {isLoading ? 'Sending...' : <><Send size={16} /> Send Invites</>}
                        </button>
                    </div>
                </div>
            </div>

            <div className="settings-section">
                <h3 className="settings-section-title">Team Members</h3>
                <div className="settings-card">
                    {members.length === 0 ? (
                        <div className="empty-state">
                            <Users size={24} style={{ opacity: 0.5 }} />
                            <span>No team members yet</span>
                        </div>
                    ) : (
                        <div className="members-list" style={{ padding: '0 16px' }}>
                            {members.map((m, idx) => (
                                <div key={idx} className="settings-row" style={{ borderBottom: idx < members.length - 1 ? '1px solid #333' : 'none' }}>
                                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                                        <span style={{ color: 'white', fontWeight: 500 }}>{m.email || 'Unknown'}</span>
                                        <span style={{ fontSize: '12px', color: '#666' }}>{m.status}</span>
                                    </div>
                                    {m.id === members[0]?.id && <span style={{ fontSize: '12px', background: '#3b82f620', color: '#3b82f6', padding: '2px 6px', borderRadius: '4px' }}>Owner</span>}
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </>
    );
};

