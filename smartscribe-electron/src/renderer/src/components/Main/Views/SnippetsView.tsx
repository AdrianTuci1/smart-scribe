

import React, { useState, useEffect, useRef } from 'react';
import { DataEntryItem } from '../../Shared/DataEntryItem';
import { Modal } from '../../Shared/Modal';
import { Switch } from '../../Shared/Switch';
import { SortMenu } from '../../Shared/SortMenu/SortMenu';
import { Snippet } from '../../../types';
import { apiService, teamService, configService } from '../../../services/api';
import { Search, RotateCcw, Trash2, Edit2, ArrowUpDown } from 'lucide-react';
import clsx from 'clsx';
import './SnippetsView.css';

export const SnippetsView: React.FC = () => {
    const [snippets, setSnippets] = useState<Snippet[]>([]);
    const [searchText, setSearchText] = useState('');
    const [isSearchOpen, setIsSearchOpen] = useState(false);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [editingSnippet, setEditingSnippet] = useState<Snippet | null>(null);
    const [isLoading, setIsLoading] = useState(false);
    const [activeTab, setActiveTab] = useState('All');

    const [page, setPage] = useState(1);
    const [hasMore, setHasMore] = useState(false);
    const [sortOrder, setSortOrder] = useState('newest');
    const [isSortMenuOpen, setIsSortMenuOpen] = useState(false);
    const [hasTeam, setHasTeam] = useState(false);
    const sortButtonRef = useRef<HTMLButtonElement>(null);

    useEffect(() => {
        configService.getSettings().then(s => setHasTeam(!!s.teamId));
    }, []);

    const loadSnippets = async (reset = false) => {
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
                apiService.getSnippets(params),
                teamService.getSharedItems('snippets', params)
            ]);

            const personal = Array.isArray(personalRes.data) ? personalRes.data.map(s => ({ ...s, type: 'personal' })) : [];
            const shared = Array.isArray(sharedRes.data) ? sharedRes.data.map(s => ({ ...s, type: 'shared' })) : [];

            if (reset) {
                setSnippets([...personal, ...shared]);
                setPage(1);
            } else {
                setSnippets(prev => {
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
            setHasMore(personalRes.meta?.has_more || sharedRes.meta?.has_more || false);
        } catch (error) {
            console.error('Failed to load snippets', error);
        } finally {
            setIsLoading(false);
        }
    };

    const displaySnippets = snippets.filter(snippet => {
        if (activeTab === 'Personal' && (snippet as any).type !== 'personal') return false;
        if (activeTab === 'Shared with team' && (snippet as any).type !== 'shared') return false;
        return true;
    });

    useEffect(() => {
        loadSnippets(true);
    }, []);

    useEffect(() => {
        const timeout = setTimeout(() => {
            loadSnippets(true);
        }, 300);
        return () => clearTimeout(timeout);
    }, [searchText, sortOrder]);

    const handleLoadMore = () => {
        loadNextPage();
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
                apiService.getSnippets(params),
                teamService.getSharedItems('snippets', params)
            ]);

            const personal = Array.isArray(personalRes.data) ? personalRes.data.map(s => ({ ...s, type: 'personal' })) : [];
            const shared = Array.isArray(sharedRes.data) ? sharedRes.data.map(s => ({ ...s, type: 'shared' })) : [];

            setSnippets(prev => [...prev, ...personal, ...shared]);
            setPage(nextPage);
            setHasMore(personalRes.meta?.has_more || sharedRes.meta?.has_more || false);
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    };

    const handleSave = async (title: string, content: string, isShared: boolean, id?: string, type?: string) => {
        if (!title || !content) return;

        try {
            const snippet = { id, title, content };

            if (id) {
                // Update
                if (type === 'shared') {
                    await teamService.updateSharedItem('snippets', snippet);
                } else {
                    await apiService.updateSnippet(snippet);
                }
            } else {
                // Add
                if (isShared) {
                    await teamService.addSharedItem('snippets', snippet);
                } else {
                    await apiService.addSnippet(snippet);
                }
            }

            loadSnippets(true);
            setEditingSnippet(null);
            setIsAddModalOpen(false);
        } catch (e) {
            console.error(e);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Are you sure you want to delete this snippet?')) return;

        const snippet = snippets.find(s => s.id === id);
        if (!snippet) return;

        try {
            if ((snippet as any).type === 'shared') {
                await teamService.deleteSharedItem('snippets', id);
            } else {
                await apiService.deleteSnippet(id);
            }
            loadSnippets(true);
        } catch (e) {
            console.error(e);
        }
    };

    return (
        <div className="snippets-container scrollbar-hide">
            <div className="snippets-content">
                {/* Top Row: Title & Add Button */}
                <div className="snippets-header">
                    <h1 className="snippets-title">Snippets</h1>
                    <button
                        onClick={() => setIsAddModalOpen(true)}
                        className="snippets-add-btn"
                    >
                        Add new
                    </button>
                </div>

                {/* Second Row: Tabs & Actions */}
                <div className="snippets-controls">
                    {/* Tabs */}
                    <div className="snippets-tabs">
                        {['All', 'Personal', 'Shared with team'].map((tab, i) => (
                            <button
                                key={tab}
                                onClick={() => setActiveTab(tab)}
                                className={clsx(
                                    "snippets-tab-btn",
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
                    <div className="snippets-actions">
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
                            onClick={(e) => {
                                e.stopPropagation();
                                setIsSortMenuOpen(!isSortMenuOpen);
                            }}
                            className="action-icon-btn"
                        >
                            <ArrowUpDown size={16} />
                        </button>
                        <button onClick={() => loadSnippets(true)} className="action-icon-btn">
                            <RotateCcw size={16} />
                        </button>
                    </div>
                </div>

                {/* List Section */}
                <div className="snippets-list">
                    {displaySnippets.length === 0 ? (
                        <div className="empty-state">
                            <p className="empty-text">{searchText ? 'No matching snippets' : 'No snippets found'}</p>
                        </div>
                    ) : (
                        displaySnippets.map((snippet, index) => (
                            <DataEntryItem
                                key={snippet.id}
                                onClick={() => setEditingSnippet(snippet)}
                                actions={
                                    <>
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                setEditingSnippet(snippet);
                                            }}
                                            className="snippet-action-btn"
                                        >
                                            <Edit2 size={16} />
                                        </button>
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                handleDelete(snippet.id);
                                            }}
                                            className="snippet-action-btn delete"
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                    </>
                                }
                            >
                                <div className="snippet-content-wrapper">
                                    <div className="snippet-title-row">
                                        <span className="snippet-title-text">{snippet.title}</span>
                                        <span className="snippet-arrow">→</span>
                                    </div>
                                    <p className="snippet-preview">{snippet.content}</p>
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

                {/* Add/Edit Modal */}
                <Modal
                    isOpen={isAddModalOpen || !!editingSnippet}
                    onClose={() => { setIsAddModalOpen(false); setEditingSnippet(null); }}
                >
                    <SnippetForm
                        initialTitle={editingSnippet?.title || ''}
                        initialContent={editingSnippet?.content || ''}
                        onCancel={() => {
                            setIsAddModalOpen(false);
                            setEditingSnippet(null);
                        }}
                        onSave={(title, content, isShared) => handleSave(title, content, isShared, editingSnippet?.id, (editingSnippet as any)?.type)}
                        hasTeam={hasTeam}
                        isEditing={!!editingSnippet}
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

const SnippetForm: React.FC<{
    initialTitle: string;
    initialContent: string;
    onCancel: () => void;
    onSave: (title: string, content: string, isShared: boolean) => void;
    hasTeam: boolean;
    isEditing: boolean;
}> = ({ initialTitle, initialContent, onCancel, onSave, hasTeam, isEditing }) => {
    const [title, setTitle] = useState(initialTitle);
    const [content, setContent] = useState(initialContent);
    const [isShared, setIsShared] = useState(false);

    return (
        <div className="snippet-form">
            {/* Share Switch */}
            <div className="switches-group">
                <Switch
                    label="Share with Team"
                    checked={isShared}
                    onChange={setIsShared}
                    disabled={!hasTeam}
                />
            </div>


            <div className="form-group">
                <label className="form-label">Snippet Title</label>
                <input
                    className="form-input"
                    placeholder="e.g. Email Signature"
                    value={title}
                    onChange={e => setTitle(e.target.value)}
                    autoFocus
                />
            </div>
            <div className="form-group">
                <label className="form-label">Content</label>
                <textarea
                    className="form-textarea"
                    value={content}
                    onChange={e => setContent(e.target.value)}
                />
            </div>

            <div className="form-actions">
                <button onClick={onCancel} className="cancel-btn">
                    Cancel
                </button>
                <button
                    onClick={() => onSave(title, content, isShared)}
                    disabled={!title || !content}
                    className="submit-btn"
                >
                    Save
                </button>
            </div>
        </div>
    )
}
