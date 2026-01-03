
import React, { useState, useEffect } from 'react';
import { DataEntryItem } from '../../Shared/DataEntryItem';
import { Note } from '../../../types';
import { apiService } from '../../../services/api';
import { Mic, Search, RotateCcw, MoreHorizontal, LayoutGrid, XCircle } from 'lucide-react';
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
                    </div>
                </div>
            </div>
        </div >
    );
};
