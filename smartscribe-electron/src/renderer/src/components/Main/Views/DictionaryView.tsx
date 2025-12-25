
import React, { useState, useEffect } from 'react';
import { DictionaryEntry } from '../../../types';
import { apiService } from '../../../services/api';
import { Search, Plus, XCircle, MoreHorizontal, RotateCcw, ArrowRight, ArrowUpDown, Trash2, Edit2 } from 'lucide-react';
import clsx from 'clsx';
import './DictionaryView.css';

export const DictionaryView: React.FC = () => {
    const [entries, setEntries] = useState<DictionaryEntry[]>([]);
    const [searchText, setSearchText] = useState('');
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [isLoading, setIsLoading] = useState(false);

    // Filtered entries
    const filteredEntries = entries.filter(entry =>
        !searchText ||
        entry.incorrectWord.toLowerCase().includes(searchText.toLowerCase()) ||
        entry.correctWord.toLowerCase().includes(searchText.toLowerCase())
    ).sort((a, b) => a.incorrectWord.localeCompare(b.incorrectWord));

    const loadEntries = async () => {
        setIsLoading(true);
        try {
            const data = await apiService.getDictionary();
            const list = Array.isArray(data) ? data : [];
            setEntries(list);
        } catch (error) {
            console.error('Failed to load dictionary', error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        loadEntries();
    }, []);

    const handleAdd = async (incorrect: string, correct: string) => {
        const newEntry = { id: crypto.randomUUID(), incorrectWord: incorrect, correctWord: correct };
        // Optimistic
        setEntries(prev => [...prev, newEntry]);
        try {
            await apiService.syncDictionary([...entries, newEntry]);
        } catch (e) {
            console.error(e);
            loadEntries(); // Revert
        }
    };

    const handleDelete = async (id: string) => {
        const newEntries = entries.filter(e => e.id !== id);
        setEntries(newEntries);
        try {
            await apiService.syncDictionary(newEntries);
        } catch (e) {
            console.error(e);
            loadEntries();
        }
    };

    return (
        <div className="dictionary-container scrollbar-hide">
            <div className="dictionary-content">
                {/* Top Row: Title & Add Button */}
                <div className="dictionary-header">
                    <h1 className="dictionary-title">Dictionary</h1>
                    <button
                        onClick={() => setIsAddModalOpen(true)}
                        className="dictionary-add-btn"
                    >
                        Add new
                    </button>
                </div>

                {/* Second Row: Tabs & Actions */}
                <div className="dictionary-controls">
                    {/* Tabs */}
                    <div className="dictionary-tabs">
                        {['All', 'Personal', 'Shared with team'].map((tab, i) => (
                            <button
                                key={tab}
                                className={clsx(
                                    "dictionary-tab-btn",
                                    i === 0 && "active"
                                )}
                            >
                                {tab}
                                {i === 0 && (
                                    <div className="tab-indicator" />
                                )}
                            </button>
                        ))}
                    </div>

                    {/* Actions */}
                    <div className="dictionary-actions">
                        {/* Search Expandable */}
                        <div className={clsx(
                            "search-container",
                            searchText && "open"
                        )}>
                            <input
                                autoFocus
                                type="text"
                                className="search-input"
                                placeholder="Search..."
                                value={searchText}
                                onChange={e => setSearchText(e.target.value)}
                                onBlur={() => !searchText && setSearchText('')} // Optional auto-close
                            />
                        </div>

                        <button
                            onClick={() => {
                                if (searchText) setSearchText('');
                                else {
                                    // Focus logic would go here, for now just toggle state if needed or let the input render
                                    setSearchText(' '); // temp hack to open, ideally use a separate isOpen state
                                    setTimeout(() => setSearchText(''), 0);
                                }
                            }}
                            className="action-icon-btn"
                        >
                            <Search size={16} />
                        </button>
                        <button className="action-icon-btn">
                            <ArrowRight size={16} /> {/* Sort Icon placeholder */}
                        </button>
                        <button onClick={loadEntries} className="action-icon-btn">
                            <RotateCcw size={16} />
                        </button>
                    </div>
                </div>

                {/* List Section */}
                <div className="dictionary-list">
                    {filteredEntries.length === 0 ? (
                        <div className="empty-state">
                            <p className="empty-text">{searchText ? 'No matching entries' : 'No dictionary entries'}</p>
                        </div>
                    ) : (
                        filteredEntries.map((entry, index) => (
                            <div key={entry.id} className="entry-item group">
                                <div className="entry-content">
                                    <span className="incorrect-word">{entry.incorrectWord}</span>
                                    <span className="arrow-separator">→</span>
                                    <span className="correct-word">{entry.correctWord}</span>
                                </div>

                                <div className="entry-actions">
                                    <button className="entry-action-btn edit">
                                        <Edit2 size={16} />
                                    </button>
                                    <button onClick={() => handleDelete(entry.id)} className="entry-action-btn delete">
                                        <Trash2 size={16} />
                                    </button>
                                </div>
                            </div>
                        ))
                    )}
                </div>

                {/* Simple Add Modal Overlay */}
                {isAddModalOpen && (
                    <div className="modal-overlay">
                        <div className="modal-content">
                            <div className="modal-header">
                                <h3 className="modal-title">Add Dictionary Entry</h3>
                                <button onClick={() => setIsAddModalOpen(false)} className="modal-close-btn"><XCircle size={20} /></button>
                            </div>
                            <AddEntryForm
                                onCancel={() => setIsAddModalOpen(false)}
                                onAdd={(inc, cor) => {
                                    handleAdd(inc, cor);
                                    setIsAddModalOpen(false);
                                }}
                            />
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

const AddEntryForm: React.FC<{ onCancel: () => void, onAdd: (incorrect: string, correct: string) => void }> = ({ onCancel, onAdd }) => {
    const [incorrect, setIncorrect] = useState('');
    const [correct, setCorrect] = useState('');

    return (
        <div className="space-y-4">
            <div className="form-group">
                <label className="form-label">Word as Spoken</label>
                <input
                    className="form-input"
                    placeholder="e.g. gonna"
                    value={incorrect}
                    onChange={e => setIncorrect(e.target.value)}
                    autoFocus
                />
            </div>
            <div className="form-group">
                <label className="form-label">Correct Word</label>
                <input
                    className="form-input"
                    placeholder="e.g. going to"
                    value={correct}
                    onChange={e => setCorrect(e.target.value)}
                />
            </div>

            <div className="form-actions">
                <button onClick={onCancel} className="cancel-btn">
                    Cancel
                </button>
                <button
                    onClick={() => onAdd(incorrect, correct)}
                    disabled={!incorrect || !correct}
                    className="submit-btn"
                >
                    Add
                </button>
            </div>
        </div>
    )
}
