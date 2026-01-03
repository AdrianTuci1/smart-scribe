

import React, { useState, useEffect, useRef } from 'react';
import { DataEntryItem } from '../../Shared/DataEntryItem';
import { SortMenu } from '../../Shared/SortMenu/SortMenu';
import { Note } from '../../../types';
import { apiService } from '../../../services/api';
import { Mic, Search, RotateCcw, MoreHorizontal, LayoutGrid, XCircle, ArrowUpDown } from 'lucide-react';
import { useAudioRecording } from '../../../hooks/useAudioRecording';
import { format } from 'date-fns';
import clsx from 'clsx';
import './NotesView.css';

export const NotesView: React.FC = () => {
    const [notes, setNotes] = useState<Note[]>([]);
    const [textInput, setTextInput] = useState('');
    const { isRecording, toggleRecording, recordingSource } = useAudioRecording({
        bypassTimer: true,
        onTranscript: (text) => setTextInput(prev => prev + (prev ? ' ' : '') + text)
    });
    const [isLoading, setIsLoading] = useState(false);

    const [page, setPage] = useState(1);
    const [hasMore, setHasMore] = useState(false);
    const [sortOrder, setSortOrder] = useState('newest');
    const [isSortMenuOpen, setIsSortMenuOpen] = useState(false);
    const [isSearchOpen, setIsSearchOpen] = useState(false); // Controls search input visibility
    const [searchQuery, setSearchQuery] = useState('');
    const sortButtonRef = useRef<HTMLButtonElement>(null);

    // Close sort menu when clicking outside
    useEffect(() => {
        if (!isSortMenuOpen) return;
        const handleClickOutside = () => setIsSortMenuOpen(false);
        document.addEventListener('click', handleClickOutside);
        return () => document.removeEventListener('click', handleClickOutside);
    }, [isSortMenuOpen]);

    const loadNotes = async (reset = false) => {
        setIsLoading(true);
        try {
            const currentPage = reset ? 1 : page;
            const res = await apiService.getNotes({
                page: currentPage,
                limit: 20,
                search: searchQuery,
                sort: sortOrder
            });

            const list = res.data || [];
            if (reset) {
                setNotes(list);
                setPage(1);
            } else {
                setNotes(prev => [...prev, ...list]);
                setPage(currentPage);
            }
            setHasMore(res.meta?.has_more || false);
        } catch (error) {
            console.error('Failed to load notes', error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        loadNotes(true);
    }, []);

    // Search and Sort effect
    useEffect(() => {
        const timeout = setTimeout(() => {
            loadNotes(true);
        }, 300);
        return () => clearTimeout(timeout);
    }, [searchQuery, sortOrder]);

    const handleLoadMore = () => {
        const nextPage = page + 1;
        setPage(nextPage); // set state update
        // Helper local func because `page` state might not update linearly in closure? 
        // `loadNotes` uses `reset ? 1 : page`.
        // We should implement `loadNextPage` for clarity or rely on state.
        // Relying on state require useEffect?
        // Simplest: pass explicit page to fetch, but update state.
        loadNextPage(nextPage);
    };

    const loadNextPage = async (nextPage: number) => {
        setIsLoading(true);
        try {
            const res = await apiService.getNotes({
                page: nextPage,
                limit: 20,
                search: searchQuery,
                sort: sortOrder
            });
            const list = res.data || [];
            setNotes(prev => [...prev, ...list]);
            setHasMore(res.meta?.has_more || false);
        } catch (e) { console.error(e); }
        finally { setIsLoading(false); }
    };

    useEffect(() => {
        loadNotes();
    }, []);

    const handleSaveNote = async () => {
        if (!textInput.trim()) return;

        const newNote: Note = {
            id: crypto.randomUUID(),
            content: textInput,
            timestamp: new Date().toISOString(),
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        // Optimistic
        setNotes(prev => [newNote, ...prev]);
        setTextInput('');

        try {
            await apiService.syncNote(newNote);
        } catch (e) {
            console.error(e);
            loadNotes();
        }
    };

    const handleFinishAndSave = () => {
        if (isRecording) toggleRecording();
        handleSaveNote();
    };

    return (
        <div className="notes-container scrollbar-hide">
            <div className="notes-content">
                {/* Header */}
                <h2 className="notes-header">
                    For quick thoughts you want to come back to
                </h2>

                {/* Main Input Card */}
                <div className="notes-card">
                    <div className="notes-input-area">
                        {!textInput && !isRecording && (
                            <span className="notes-placeholder">Start typing or recording...</span>
                        )}
                        <textarea
                            autoFocus
                            className="notes-textarea"
                            value={textInput}
                            onChange={(e) => setTextInput(e.target.value)}
                        />
                    </div>

                    {/* Controls inside card */}
                    <div className="notes-controls">
                        <div className="notes-spacer"></div> {/* Spacer */}

                        {/* Mic Toggle - Hidden if recording (per requirements) */}
                        {!isRecording && (
                            <button
                                onClick={toggleRecording}
                                className="mic-btn"
                            >
                                <Mic size={18} />
                            </button>
                        )}

                        {/* Finish Button - Only if recording started locally */}
                        {isRecording && recordingSource === 'local' && (
                            <button
                                onClick={handleFinishAndSave}
                                className="finish-btn"
                            >
                                Finish
                            </button>
                        )}

                        {/* If not recording, show nothing or just Save? Original had Finish disabled until text. 
                            Requirements say "Finish button appears ONLY if recording is started in notesview".
                            Does it imply we can't save manually without recording?
                            Probably just meant the "Finish Recording" button.
                            If I type manually, I should be able to save.
                            But "Finish" usually means "Finish Note".
                            If isRecording is FALSE, should we show a Save button?
                            Original code showed "Finish" button always (disabled if no text).
                            New requirement: "Buttonul de finish apare doar daca inregistrarea e pornita in notesview".
                            This might be strict.
                            But if I *type* a note, how do I save it?
                            Maybe the user implies the "Recording Finish" button.
                            I will assume if NOT recording, we still need a way to save.
                            Or maybe the UI changes mode.
                            Let's keep "Finish" available if NOT recording but has text? 
                            User said "Finish button appears ONLY if recording is started".
                            This might effectively hide it for manual entry?
                            I will implement strictly first: Only if `isRecording && local`.
                            Wait, manual entry needs save. 
                            I'll assume "Finish" for *Recording* context.
                            I'll add a "Save" or "Add" button for manual? Or keep the "Finish" button logic as:
                            Visible if (isRecording && local) OR (!isRecording && textInput)
                            But "record button from notesview disappears".
                            If I implement exactly:
                            - Recording (Local): Show Finish. Hide Mic.
                            - Recording (External): Hide Mic. Hide Finish.
                            - IDLE: Show Mic. Show Finish (if text)?
                            Use logic: `(isRecording && source === 'local') || (!isRecording && textInput)`
                            This preserves manual save capability.
                        */}
                        {!isRecording && textInput && (
                            <button
                                onClick={handleSaveNote}
                                className="finish-btn"
                            >
                                Save
                            </button>
                        )}
                    </div>
                </div>

                {/* List Section */}
                <div className="recents-section">
                    <div className="recents-header">
                        <span className="recents-title">RECENTS</span>
                        <div className="recents-actions">
                            {/* Search */}
                            <div className={clsx("relative flex items-center transition-all bg-[#2a2a2a] rounded", isSearchOpen ? "w-48 px-2" : "w-8 bg-transparent")}>
                                <button
                                    onClick={() => {
                                        if (isSearchOpen && !searchQuery) {
                                            setIsSearchOpen(false);
                                        } else if (isSearchOpen && searchQuery) {
                                            setSearchQuery('');
                                            setIsSearchOpen(false);
                                        } else {
                                            setIsSearchOpen(true);
                                        }
                                    }}
                                    className="recents-action-btn"
                                >
                                    <Search size={16} />
                                </button>
                                {isSearchOpen && (
                                    <input
                                        autoFocus
                                        className="bg-transparent border-none outline-none text-xs text-white ml-2 w-full"
                                        placeholder="Search..."
                                        value={searchQuery}
                                        onChange={e => setSearchQuery(e.target.value)}
                                    />
                                )}
                            </div>

                            {/* Sort */}
                            <button
                                ref={sortButtonRef}
                                className="recents-action-btn"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    setIsSortMenuOpen(!isSortMenuOpen);
                                }}
                            >
                                <ArrowUpDown size={16} />
                            </button>

                            <button onClick={() => loadNotes(true)} className="recents-action-btn"><RotateCcw size={16} /></button>
                        </div>
                    </div>

                    <div className="recents-list">
                        {notes.length === 0 ? (
                            <div className="empty-notes">
                                <p>No notes found</p>
                            </div>
                        ) : (
                            notes.map(note => (
                                <DataEntryItem
                                    key={note.id}
                                    onClick={() => setTextInput(prev => prev ? prev + ' ' + note.content : note.content)}
                                >
                                    <p className="note-content">
                                        {typeof note.content === 'string' ? note.content : JSON.stringify(note.content)}
                                    </p>
                                    <span className="note-date">
                                        {format(new Date(note.updatedAt), 'MMM d')}
                                    </span>
                                </DataEntryItem>
                            ))
                        )}
                        {hasMore && (
                            <div className="py-4 flex justify-center">
                                <button
                                    onClick={handleLoadMore}
                                    disabled={isLoading}
                                    className="text-sm text-gray-400 hover:text-white transition-colors disabled:opacity-50"
                                >
                                    {isLoading ? 'Loading...' : 'Load More'}
                                </button>
                            </div>
                        )}
                    </div>
                </div>

                {/* Sort Menu */}
                <SortMenu
                    isOpen={isSortMenuOpen}
                    onClose={() => setIsSortMenuOpen(false)}
                    sortOrder={sortOrder}
                    onSortChange={setSortOrder}
                    buttonRef={sortButtonRef}
                />
            </div>
        </div >
    );
};
