
import React, { useEffect, useState, useMemo } from 'react';
import { Transcript } from '../../../types';
import { apiService } from '../../../services/api';
import { TranscriptRow } from './TranscriptRow';
import { Flame, PenTool, ThumbsUp, Loader2 } from 'lucide-react';
import { format, isSameMinute, isSameHour } from 'date-fns';
import './HomeView.css';

// Helper to group transcripts by date string (e.g. "Today", "Yesterday")
const groupTranscripts = (transcripts: Transcript[]) => {
    // Simplified grouping for now
    const groups: { [key: string]: Transcript[] } = {};
    transcripts.forEach(t => {
        const date = new Date(t.timestamp);
        const day = format(date, 'EEEE, MMMM d'); // "Monday, December 25"
        if (!groups[day]) groups[day] = [];
        groups[day].push(t);
    });
    return Object.entries(groups).map(([date, list]) => ({ date, list }));
};

export const HomeView: React.FC = () => {
    const [transcripts, setTranscripts] = useState<Transcript[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [stats, setStats] = useState({ streak: 1, words: 0, wpm: 0 }); // Mock stats for now

    const loadData = async () => {
        setIsLoading(true);
        try {
            // Fetch transcripts
            const data = await apiService.getTranscripts();
            // Ensure data is array
            const list = Array.isArray(data) ? data : [];
            // Sort by date desc
            list.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
            setTranscripts(list);

            if (list.length > 0 && (window as any).electron) {
                const latest = list[0];
                if (latest && latest.text) {
                    (window as any).electron.ipcRenderer.invoke('set-setting', 'lastTranscript', latest.text);
                    (window as any).electron.ipcRenderer.send('update-tray');
                }
            }

            // Calculate stats
            const words = list.reduce((acc, t) => acc + (t.text ? t.text.split(' ').length : 0), 0);
            setStats({
                streak: 1, // Mock
                words,
                wpm: words > 0 ? 65 : 0 // Mock/Simple calc
            });
        } catch (error) {
            console.error('Failed to load transcripts', error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        loadData();
    }, []);

    const groupedTranscripts = useMemo(() => groupTranscripts(transcripts), [transcripts]);

    // Handlers
    const handleCopy = (t: Transcript) => {
        navigator.clipboard.writeText(t.text);
    };

    const handleFlag = async (t: Transcript) => {
        // Optimistic update
        const updated = { ...t, isFlagged: !t.isFlagged };
        setTranscripts(prev => prev.map(item => item.id === t.id ? updated : item));
        try {
            await apiService.updateTranscript(updated);
        } catch (e) {
            console.error(e);
            // Revert on error
            setTranscripts(prev => prev.map(item => item.id === t.id ? t : item));
        }
    };

    const handleDelete = async (t: Transcript) => {
        // Optimistic
        setTranscripts(prev => prev.filter(item => item.id !== t.id));
        try {
            await apiService.deleteTranscript(t.id);
        } catch (e) {
            console.error(e);
            // Revert? Hard to revert delete without re-fetching or keeping copy
            loadData();
        }
    };

    const shouldShowTime = (t: Transcript, list: Transcript[], index: number) => {
        if (index === 0) return true;
        const prev = list[index - 1];
        const d1 = new Date(t.timestamp);
        const d2 = new Date(prev.timestamp);
        return !isSameMinute(d1, d2) || !isSameHour(d1, d2);
    };

    return (
        <div className="home-container scrollbar-hide">
            <div className="home-content">
                {/* Header Row */}
                <div className="home-header">
                    <h1 className="home-title">Welcome back, Tucicovenco</h1>

                    {/* Stats Pill */}
                    <div className="stats-pill">
                        <div className="stat-item">
                            <span className="stat-icon orange">🔥</span>
                            <span>{stats.streak} weeks</span>
                        </div>
                        <div className="stat-divider" />
                        <div className="stat-item">
                            <span className="stat-icon blue">🚀</span>
                            <span>{stats.words} words</span>
                        </div>
                        <div className="stat-divider" />
                        <div className="stat-item">
                            <span className="stat-icon yellow">👍</span>
                            <span>{stats.wpm} WPM</span>
                        </div>
                    </div>
                </div>

                {/* Flow Section */}
                <div className="flow-section">
                    <h2 className="flow-title">
                        Get back into your <span>Flow</span>
                    </h2>
                    <div className="flow-grid">
                        {/* Card 1: Apple Notes */}
                        <button className="flow-card group">
                            <div className="flow-icon-wrapper notes">
                                {/* Use an icon or image here. Simple folder icon for now */}
                                <svg className="flow-icon-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path></svg>
                            </div>
                            <span className="flow-card-label">
                                Apple Notes
                                <span className="flow-arrow">↗</span>
                            </span>
                        </button>

                        {/* Card 2: Google Antigravity */}
                        <button className="flow-card group">
                            <div className="flow-icon-wrapper antigravity">
                                <svg className="flow-icon-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="2" y1="12" x2="22" y2="12"></line><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path></svg>
                            </div>
                            <span className="flow-card-label">
                                Google Antigravity
                                <span className="flow-arrow">↗</span>
                            </span>
                        </button>

                        {/* Card 3: Cursor */}
                        <button className="flow-card group">
                            <div className="flow-icon-wrapper cursor">
                                {/* Cursor logo approx */}
                                <svg className="flow-icon-svg" viewBox="0 0 24 24" fill="currentColor"><path d="M21 13v10h-6v-6h-6v6h-6v-10h4.3c-0.5-1.7-1.3-3.0-2.3-4.1l3-1.8c2 2.3 2.7 5.7 3 10.9h6c0-5.7 1.5-8.5 4.5-9.4l0.4 3.4c-1.3 0.4-2.2 1.5-2.9 3.1h6z"></path></svg>
                            </div>
                            <span className="flow-card-label">
                                Cursor
                                <span className="flow-arrow">↗</span>
                            </span>
                        </button>
                    </div>
                </div>

                {/* Timeline Section */}
                {isLoading ? (
                    <div className="loading-container">
                        <Loader2 className="loading-spinner" size={24} />
                    </div>
                ) : transcripts.length === 0 ? (
                    <div className="empty-container">
                        <p>No transcripts yet</p>
                        <button onClick={loadData} className="refresh-btn">Refresh</button>
                    </div>
                ) : (
                    <div className="timeline-section">
                        {groupedTranscripts.map(({ date, list }) => (
                            <div key={date}>
                                <h3 className="date-header">
                                    {date}
                                </h3>
                                <div className="transcript-group">
                                    {list.map((t, index) => (
                                        <TranscriptRow
                                            key={t.id}
                                            transcript={t}
                                            showTime={true}
                                            isLast={index === list.length - 1}
                                            onCopy={handleCopy}
                                            onFlag={handleFlag}
                                            onUndoAIEdit={() => console.log('Undo AI edit', t.id)}
                                            onRetry={() => console.log('Retry transcript', t.id)}
                                            onDelete={handleDelete}
                                            onDownloadAudio={() => console.log('Download', t.id)}
                                        />
                                    ))}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};
