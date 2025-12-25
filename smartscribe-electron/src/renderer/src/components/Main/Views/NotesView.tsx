
import React, { useState, useEffect } from 'react';
import { Note } from '../../../types';
import { apiService } from '../../../services/api';
import { Mic, Search, RotateCcw, MoreHorizontal, LayoutGrid, XCircle } from 'lucide-react';
import { format } from 'date-fns';
import clsx from 'clsx';
import './NotesView.css';

export const NotesView: React.FC = () => {
    const [notes, setNotes] = useState<Note[]>([]);
    const [textInput, setTextInput] = useState('');
    const [isRecording, setIsRecording] = useState(false);
    const [isLoading, setIsLoading] = useState(false);

    const loadNotes = async () => {
        setIsLoading(true);
        try {
            const data = await apiService.getNotes();
            const list = Array.isArray(data) ? data : [];
            // Sort by updated desc
            list.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
            setNotes(list);
        } catch (error) {
            console.error('Failed to load notes', error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        loadNotes();
    }, []);

    const handleSaveNote = async () => {
        if (!textInput.trim()) return;

        const newNote: Note = {
            id: crypto.randomUUID(),
            content: textInput,
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

    const handleMicToggle = () => {
        setIsRecording(!isRecording);
        // Mock recording logic: if stopping and has text, save. 
        // Real app would transcribe audio. 
        if (isRecording) {
            if (textInput) handleSaveNote();
        } else {
            // Start recording... (simulate dictation)
            // For now just focus input
        }
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

                        {/* Mic Toggle (Top Right or inline?) Image shows Mic in top right, Finish button bottom right. */}
                        <button
                            onClick={handleMicToggle}
                            className={clsx(
                                "mic-btn",
                                isRecording && "recording"
                            )}
                        >
                            <Mic size={18} fill={isRecording ? "currentColor" : "none"} />
                        </button>

                        <button
                            onClick={handleSaveNote}
                            disabled={!textInput}
                            className="finish-btn"
                        >
                            Finish
                        </button>
                    </div>
                </div>

                {/* List Section */}
                <div className="recents-section">
                    <div className="recents-header">
                        <span className="recents-title">RECENTS</span>
                        <div className="recents-actions">
                            <button className="recents-action-btn"><Search size={16} /></button>
                            <button className="recents-action-btn"><MoreHorizontal size={16} /></button>
                            <button onClick={loadNotes} className="recents-action-btn"><RotateCcw size={16} /></button>
                        </div>
                    </div>

                    <div className="recents-list">
                        {notes.length === 0 ? (
                            <div className="empty-notes">
                                <p>No notes found</p>
                            </div>
                        ) : (
                            notes.map(note => (
                                <div
                                    key={note.id}
                                    onClick={() => setTextInput(prev => prev ? prev + ' ' + note.content : note.content)}
                                    className="note-item group"
                                >
                                    <p className="note-content">
                                        {note.content}
                                    </p>
                                    <span className="note-date">
                                        {format(new Date(note.updatedAt), 'MMM d')}
                                    </span>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};
