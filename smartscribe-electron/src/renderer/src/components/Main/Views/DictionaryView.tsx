

import React, { useState, useEffect, useRef } from 'react';
import { DataEntryItem } from '../../Shared/DataEntryItem';
import { Modal } from '../../Shared/Modal';
import { Switch } from '../../Shared/Switch';
import { SortMenu } from '../../Shared/SortMenu/SortMenu';
import { DictionaryEntry } from '../../../types';
import { apiService, teamService, configService } from '../../../services/api';
import { Search, RotateCcw, ArrowUpDown, Trash2, Edit2 } from 'lucide-react';
import clsx from 'clsx';
import './DictionaryView.css';

export const DictionaryView: React.FC = () => {
    const [entries, setEntries] = useState<DictionaryEntry[]>([]);
    const [searchText, setSearchText] = useState('');
    const [isSearchOpen, setIsSearchOpen] = useState(false);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [editingEntry, setEditingEntry] = useState<DictionaryEntry | null>(null);
    const [isLoading, setIsLoading] = useState(false);
    const [activeTab, setActiveTab] = useState('All');

    const [page, setPage] = useState(1);
    const [hasMore, setHasMore] = useState(false);
    const [sortOrder, setSortOrder] = useState('newest'); // 'newest', 'oldest', 'alphabetical'
    const [isSortMenuOpen, setIsSortMenuOpen] = useState(false);
    const [hasTeam, setHasTeam] = useState(false);
    const sortButtonRef = useRef<HTMLButtonElement>(null);

    useEffect(() => {
        configService.getSettings().then(s => setHasTeam(!!s.teamId));
    }, []);

    const loadEntries = async (reset = false) => {
        setIsLoading(true);
        try {
            const currentPage = reset ? 1 : page;
            const limit = 20;

            const params = {
                page: currentPage,
                limit,
                search: searchText,
                sort: sortOrder
            };

            const [personalRes, sharedRes] = await Promise.all([
                apiService.getDictionary(params),
                teamService.getSharedItems('dictionary', params)
            ]);

            const personal = Array.isArray(personalRes.data) ? personalRes.data.map(e => ({ ...e, type: 'personal' })) : [];
            const shared = Array.isArray(sharedRes.data) ? sharedRes.data.map(e => ({ ...e, type: 'shared' })) : [];

            if (reset) {
                setEntries([...personal, ...shared]);
                setPage(1);
            } else {
                setEntries(prev => {
                    // Start with ALL previous items
                    // Filter out any that we are about to replace?
                    // Pagination usually implies appending new pages.
                    // But if we have mixed sources...
                    // Let's just append new results to the accumulation.
                    // We need to deduplicate based on ID if necessary, but assuming clean pagination:
                    return [...prev, ...personal, ...shared];
                });
                setPage(currentPage);
            }
            // If either has more, we show load more.
            setHasMore(personalRes.meta?.has_more || sharedRes.meta?.has_more || false);
        } catch (error) {
            console.error('Failed to load dictionary', error);
        } finally {
            setIsLoading(false);
        }
    };

    const loadNextPage = async () => {
        const nextPage = page + 1;
        setIsLoading(true);
        try {
            const limit = 20;
            const params = {
                page: nextPage,
                limit,
                search: searchText,
                sort: sortOrder
            };
            const [personalRes, sharedRes] = await Promise.all([
                apiService.getDictionary(params),
                teamService.getSharedItems('dictionary', params)
            ]);

            const personal = Array.isArray(personalRes.data) ? personalRes.data.map(e => ({ ...e, type: 'personal' })) : [];
            const shared = Array.isArray(sharedRes.data) ? sharedRes.data.map(e => ({ ...e, type: 'shared' })) : [];

            setEntries(prev => [...prev, ...personal, ...shared]);
            setPage(nextPage);
            setHasMore(personalRes.meta?.has_more || sharedRes.meta?.has_more || false);
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    };

    const handleLoadMore = () => {
        loadNextPage();
    };

    useEffect(() => {
        loadEntries(true);
    }, []);

    // Trigger reload when Sort/Search changes
    useEffect(() => {
        const timeout = setTimeout(() => {
            loadEntries(true);
        }, 300); // Debounce search
        return () => clearTimeout(timeout);
    }, [searchText, sortOrder]);

    const handleSave = async (incorrect: string, correct: string, isShared: boolean, id?: string, type?: string) => {
        try {
            const entry = { incorrectWord: incorrect, correctWord: correct, id };
            if (id) {
                // Update
                if (type === 'shared') {
                    await teamService.updateSharedItem('dictionary', entry);
                } else {
                    await apiService.updateDictionaryEntry(entry);
                }
            } else {
                // Add
                if (isShared) {
                    await teamService.addSharedItem('dictionary', entry);
                } else {
                    await apiService.addDictionaryEntry(entry);
                }
            }
            loadEntries(true);
            setIsAddModalOpen(false);
            setEditingEntry(null);
        } catch (e) {
            console.error(e);
        }
    };

    const handleDelete = async (id: string) => {
        const entry = entries.find(e => e.id === id);
        if (!entry) return;

        try {
            if ((entry as any).type === 'shared') {
                await teamService.deleteSharedItem('dictionary', id);
            } else {
                await apiService.deleteDictionaryEntry(id);
            }
            loadEntries(true);
        } catch (e) {
            console.error(e);
        }
    };

    const displayEntries = entries.filter(entry => {
        if (activeTab === 'Personal' && (entry as any).type !== 'personal') return false;
        if (activeTab === 'Shared with team' && (entry as any).type !== 'shared') return false;
        return true;
    });

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
                            isSearchOpen && "open"
                        )}>
                            <input
                                autoFocus
                                type="text"
                                className="search-input"
                                placeholder="Search..."
                                value={searchText}
                                onChange={e => setSearchText(e.target.value)}
                                onBlur={() => {
                                    if (!searchText) {
                                        setIsSearchOpen(false);
                                    }
                                }}
                            />
                        </div>

                        <button
                            onClick={() => {
                                if (isSearchOpen && !searchText) {
                                    setIsSearchOpen(false);
                                } else if (isSearchOpen && searchText) {
                                    setSearchText('');
                                    setIsSearchOpen(false);
                                } else {
                                    setIsSearchOpen(true);
                                }
                            }}
                            className="action-icon-btn"
                        >
                            <Search size={16} />
                        </button>
                        <button
                            ref={sortButtonRef}
                            className="action-icon-btn"
                            onClick={(e) => {
                                e.stopPropagation();
                                setIsSortMenuOpen(!isSortMenuOpen);
                            }}
                        >
                            <ArrowUpDown size={16} />
                        </button>
                        <button onClick={() => loadEntries(true)} className="action-icon-btn">
                            <RotateCcw size={16} />
                        </button>
                    </div>
                </div>

                {/* List Section */}
                <div className="dictionary-list">
                    {displayEntries.length === 0 ? (
                        <div className="empty-state">
                            <p className="empty-text">{searchText ? 'No matching entries' : 'No dictionary entries'}</p>
                        </div>
                    ) : (
                        displayEntries.map((entry) => (
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

                {/* Valid Add/Edit Modal */}
                <Modal
                    isOpen={isAddModalOpen || !!editingEntry}
                    onClose={() => {
                        setIsAddModalOpen(false);
                        setEditingEntry(null);
                    }}
                >
                    <EntryForm
                        initialIncorrect={editingEntry?.incorrectWord || ''}
                        initialCorrect={editingEntry?.correctWord || ''}
                        onCancel={() => {
                            setIsAddModalOpen(false);
                            setEditingEntry(null);
                        }}
                        onSave={(inc, cor, isShared) => handleSave(inc, cor, isShared, editingEntry?.id, (editingEntry as any)?.type)}
                        hasTeam={hasTeam}
                        isEditing={!!editingEntry}
                    />
                </Modal>

                {/* Sort Menu */}
                <SortMenu
                    isOpen={isSortMenuOpen}
                    onClose={() => setIsSortMenuOpen(false)}
                    sortOrder={sortOrder}
                    onSortChange={setSortOrder}
                    buttonRef={sortButtonRef}
                />
            </div>
        </div>
    );
};

const EntryForm: React.FC<{
    initialIncorrect: string;
    initialCorrect: string;
    onCancel: () => void;
    onSave: (incorrect: string, correct: string, isShared: boolean) => void;
    hasTeam: boolean;
    isEditing: boolean;
}> = ({ initialIncorrect, initialCorrect, onCancel, onSave, hasTeam, isEditing }) => {
    const [incorrect, setIncorrect] = useState(initialIncorrect);
    const [correct, setCorrect] = useState(initialCorrect);
    const [isCorrection, setIsCorrection] = useState(!!initialIncorrect && initialIncorrect !== initialCorrect);
    const [isShared, setIsShared] = useState(false);

    useEffect(() => {
        setIncorrect(initialIncorrect);
        setCorrect(initialCorrect);
        if (isEditing) {
            setIsCorrection(!!initialIncorrect && initialIncorrect !== initialCorrect);
        }
    }, [initialIncorrect, initialCorrect, isEditing]);

    return (
        <div className="entry-form">
            {/* Switches */}
            <div className="switches-group">
                <Switch
                    label="Correct Misspelling"
                    checked={isCorrection}
                    onChange={setIsCorrection}
                />
                <Switch
                    label="Share with Team"
                    checked={isShared}
                    onChange={setIsShared}
                    disabled={!hasTeam}
                />
            </div>


            {isCorrection ? (
                <>
                    <div className="form-group">
                        <label className="form-label">Word as Spoken (Incorrect)</label>
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
                </>
            ) : (
                <div className="form-group">
                    <label className="form-label">Word</label>
                    <input
                        className="form-input"
                        placeholder="e.g. uniqueName"
                        value={correct}
                        onChange={e => {
                            setCorrect(e.target.value);
                            setIncorrect(e.target.value);
                        }}
                        autoFocus
                    />
                </div>
            )}

            <div className="form-actions">
                <button onClick={onCancel} className="cancel-btn">
                    Cancel
                </button>
                <button
                    onClick={() => onSave(incorrect, correct, isShared)}
                    disabled={!correct || (isCorrection && !incorrect)}
                    className="submit-btn"
                >
                    Save
                </button>
            </div>
        </div>
    )
}
