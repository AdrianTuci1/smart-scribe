
import React, { useEffect, useState, useMemo } from 'react';
import { Transcript } from '../../../types';
import { apiService } from '../../../services/api';
import { TranscriptRow } from './TranscriptRow';
import { Flame, PenTool, ThumbsUp, Loader2 } from 'lucide-react';
import { format, isSameMinute, isSameHour } from 'date-fns';
import { useAuth } from '../../../contexts/AuthContext';
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
    const { user } = useAuth();
    const [transcripts, setTranscripts] = useState<Transcript[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [stats, setStats] = useState({ streak: 1, words: 0, wpm: 0 }); // Mock stats for now

    const loadData = async () => {
        setIsLoading(true);
        try {
            // Fetch transcripts and stats in parallel
            const [transcriptsData, statsData] = await Promise.all([
                apiService.getTranscripts(),
                apiService.getUserStats().catch(err => {
                    console.warn('Failed to load stats, using calculated values', err);
                    return null;
                })
            ]);

            // Process transcripts
            const list = Array.isArray(transcriptsData) ? transcriptsData : [];
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

            // Use stats from API if available, otherwise calculate from transcripts
            if (statsData && statsData.streak !== undefined) {
                setStats({
                    streak: statsData.streak || 0,
                    words: statsData.totalWords || 0,
                    wpm: statsData.averageWpm || 0
                });
            } else {
                // Fallback: Calculate stats from transcripts
                const words = list.reduce((acc, t) => acc + (t.text ? t.text.split(' ').length : 0), 0);
                setStats({
                    streak: 1, // Mock
                    words,
                    wpm: words > 0 ? 65 : 0 // Mock/Simple calc
                });
            }
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
        navigator.clipboard.writeText(t.text || '');
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
                    <h1 className="home-title">Welcome back, {user?.username || 'User'}</h1>

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
                                            onRetry={async () => {
                                                try {
                                                    await apiService.retryTranscription(t.id);
                                                    // Reload transcripts after retry
                                                    loadData();
                                                } catch (error) {
                                                    console.error('Failed to retry transcription', error);
                                                }
                                            }}
                                            onDelete={handleDelete}
                                            onDownloadAudio={async (transcript) => {
                                                try {
                                                    const blob = await apiService.downloadAudio(transcript.id);
                                                    // Create a download link
                                                    const url = window.URL.createObjectURL(blob);
                                                    const a = document.createElement('a');
                                                    a.href = url;
                                                    a.download = `transcript-${transcript.id}.mp3`;
                                                    document.body.appendChild(a);
                                                    a.click();
                                                    window.URL.revokeObjectURL(url);
                                                    document.body.removeChild(a);
                                                } catch (error) {
                                                    console.error('Failed to download audio', error);
                                                }
                                            }}
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
