
import React, { useState, useEffect } from 'react';
import { DataEntryItem } from '../../Shared/DataEntryItem';
import { Modal } from '../../Shared/Modal';
import { DictionaryEntry } from '../../../types';
import { apiService, teamService } from '../../../services/api';
import { Search, Plus, XCircle, MoreHorizontal, RotateCcw, ArrowRight, ArrowUpDown, Trash2, Edit2 } from 'lucide-react';
import clsx from 'clsx';
import './DictionaryView.css';
// ...
export const DictionaryView: React.FC = () => {
    const [entries, setEntries] = useState<DictionaryEntry[]>([]);
    const [searchText, setSearchText] = useState('');
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [editingEntry, setEditingEntry] = useState<DictionaryEntry | null>(null);
    const [isLoading, setIsLoading] = useState(false);
    const [activeTab, setActiveTab] = useState('All');

    // Filtered entries
    const filteredEntries = entries.filter(entry => {
        // Tab Filter
        if (activeTab === 'Personal' && (entry as any).type !== 'personal') return false;
        if (activeTab === 'Shared with team' && (entry as any).type !== 'shared') return false;

        return !searchText ||
            entry.incorrectWord.toLowerCase().includes(searchText.toLowerCase()) ||
            entry.correctWord.toLowerCase().includes(searchText.toLowerCase())
    }).sort((a, b) => a.incorrectWord.localeCompare(b.incorrectWord));

    const loadEntries = async () => {
        setIsLoading(true);
        try {
            const [personalData, sharedData] = await Promise.all([
                apiService.getDictionary(),
                teamService.getSharedItems('dictionary')
            ]);

            const personal = Array.isArray(personalData) ? personalData.map(e => ({ ...e, type: 'personal' })) : [];
            const shared = Array.isArray(sharedData) ? sharedData.map(e => ({ ...e, type: 'shared' })) : [];

            setEntries([...personal, ...shared]);
        } catch (error) {
            console.error('Failed to load dictionary', error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        loadEntries();
    }, []);

    const handleSave = async (incorrect: string, correct: string, id?: string) => {
        let newEntries = [...entries];

        if (id) {
            // Update existing
            newEntries = newEntries.map(e => e.id === id ? { ...e, incorrectWord: incorrect, correctWord: correct } : e);
        } else {
            // Add new
            const newEntry = { id: crypto.randomUUID(), incorrectWord: incorrect, correctWord: correct };
            newEntries.push(newEntry);
        }

        setEntries(newEntries);

        // Reset states
        setIsAddModalOpen(false);
        setEditingEntry(null);

        try {
            await apiService.syncDictionary(newEntries);
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
                                onClick={() => setActiveTab(tab)}
                                className={clsx(
                                    "dictionary-tab-btn",
                                    activeTab === tab && "active"
                                )}
                            >
                                {tab}
                                {activeTab === tab && (
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
                            <DataEntryItem
                                key={entry.id}
                                actions={
                                    <>
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                setEditingEntry(entry);
                                            }}
                                            className="entry-action-btn edit"
                                        >
                                            <Edit2 size={16} />
                                        </button>
                                        <button onClick={() => handleDelete(entry.id)} className="entry-action-btn delete">
                                            <Trash2 size={16} />
                                        </button>
                                    </>
                                }
                            >
                                <div className="entry-content">
                                    <span className="incorrect-word">{entry.incorrectWord}</span>
                                    <span className="arrow-separator">→</span>
                                    <span className="correct-word">{entry.correctWord}</span>
                                </div>
                            </DataEntryItem>
                        ))
                    )}
                </div>

                {/* Valid Add/Edit Modal */}
                <Modal
                    isOpen={isAddModalOpen || !!editingEntry}
                    onClose={() => {
                        setIsAddModalOpen(false);
                        setEditingEntry(null);
                    }}
                    title={editingEntry ? 'Edit Entry' : 'Add Dictionary Entry'}
                >
                    <EntryForm
                        initialIncorrect={editingEntry?.incorrectWord || ''}
                        initialCorrect={editingEntry?.correctWord || ''}
                        onCancel={() => {
                            setIsAddModalOpen(false);
                            setEditingEntry(null);
                        }}
                        onSave={(inc, cor) => handleSave(inc, cor, editingEntry?.id)}
                    />
                </Modal>
            </div>
        </div>
    );
};

const EntryForm: React.FC<{
    initialIncorrect: string;
    initialCorrect: string;
    onCancel: () => void;
    onSave: (incorrect: string, correct: string) => void;
}> = ({ initialIncorrect, initialCorrect, onCancel, onSave }) => {
    const [incorrect, setIncorrect] = useState(initialIncorrect);
    const [correct, setCorrect] = useState(initialCorrect);

    useEffect(() => {
        setIncorrect(initialIncorrect);
        setCorrect(initialCorrect);
    }, [initialIncorrect, initialCorrect]);

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
                    onClick={() => onSave(incorrect, correct)}
                    disabled={!incorrect || !correct}
                    className="submit-btn"
                >
                    Save
                </button>
            </div>
        </div>
    )
}
