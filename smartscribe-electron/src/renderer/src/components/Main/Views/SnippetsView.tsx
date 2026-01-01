
import React, { useState, useEffect } from 'react';
import { DataEntryItem } from '../../Shared/DataEntryItem';
import { Modal } from '../../Shared/Modal';
import { Snippet } from '../../../types';
import { apiService } from '../../../services/api';
import { Search, Plus, XCircle, MoreHorizontal, RotateCcw, Trash2, Edit2, Copy, ArrowUpDown } from 'lucide-react';
import clsx from 'clsx';
import './SnippetsView.css';

export const SnippetsView: React.FC = () => {
    const [snippets, setSnippets] = useState<Snippet[]>([]);
    const [searchText, setSearchText] = useState('');
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [editingSnippet, setEditingSnippet] = useState<Snippet | null>(null);
    const [isLoading, setIsLoading] = useState(false);

    // Filtered snippets
    const filteredSnippets = snippets.filter(snippet =>
        !searchText ||
        snippet.title.toLowerCase().includes(searchText.toLowerCase()) ||
        snippet.content.toLowerCase().includes(searchText.toLowerCase())
    ).sort((a, b) => a.title.localeCompare(b.title));

    const loadSnippets = async () => {
        setIsLoading(true);
        try {
            const data = await apiService.getSnippets();
            const list = Array.isArray(data) ? data : [];
            setSnippets(list);
        } catch (error) {
            console.error('Failed to load snippets', error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        loadSnippets();
    }, []);

    const handleSave = async (title: string, content: string, id?: string) => {
        if (!title || !content) return;

        let newSnippets = [...snippets];
        if (id) {
            // Update
            const updated = { id, title, content };
            newSnippets = newSnippets.map(s => s.id === id ? updated : s);
        } else {
            // Add
            const newSnippet = { id: crypto.randomUUID(), title, content };
            newSnippets.push(newSnippet);
        }

        // Optimistic
        setSnippets(newSnippets);
        setEditingSnippet(null);
        setIsAddModalOpen(false);

        try {
            await apiService.syncSnippets(newSnippets);
        } catch (e) {
            console.error(e);
            loadSnippets(); // Revert
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Are you sure you want to delete this snippet?')) return;

        const newSnippets = snippets.filter(s => s.id !== id);
        setSnippets(newSnippets);
        try {
            await apiService.syncSnippets(newSnippets);
        } catch (e) {
            console.error(e);
            loadSnippets();
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
                                className={clsx(
                                    "snippets-tab-btn",
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
                    <div className="snippets-actions">
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
                                onBlur={() => !searchText && setSearchText('')}
                            />
                        </div>
                        <button
                            onClick={() => {
                                if (searchText) setSearchText('');
                                else {
                                    setSearchText(' ');
                                    setTimeout(() => setSearchText(''), 0);
                                }
                            }}
                            className="action-icon-btn"
                        >
                            <Search size={16} />
                        </button>
                        <button className="action-icon-btn">
                            <ArrowUpDown size={16} />
                        </button>
                        <button onClick={loadSnippets} className="action-icon-btn">
                            <RotateCcw size={16} />
                        </button>
                    </div>
                </div>

                {/* List Section */}
                <div className="snippets-list">
                    {filteredSnippets.length === 0 ? (
                        <div className="empty-state">
                            <p className="empty-text">{searchText ? 'No matching snippets' : 'No snippets found'}</p>
                        </div>
                    ) : (
                        filteredSnippets.map((snippet, index) => (
                            <DataEntryItem
                                key={snippet.id}
                                onClick={() => setEditingSnippet(snippet)}
                                actions={
                                    <>
                                        <button className="snippet-action-btn">
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
                </div>

                {/* Add/Edit Modal */}
                <Modal
                    isOpen={isAddModalOpen || !!editingSnippet}
                    onClose={() => { setIsAddModalOpen(false); setEditingSnippet(null); }}
                    title={editingSnippet ? 'Edit Snippet' : 'Add Snippet'}
                >
                    <SnippetForm
                        initialTitle={editingSnippet?.title || ''}
                        initialContent={editingSnippet?.content || ''}
                        onCancel={() => {
                            setIsAddModalOpen(false);
                            setEditingSnippet(null);
                        }}
                        onSave={(title, content) => handleSave(title, content, editingSnippet?.id)}
                    />
                </Modal>
            </div>
        </div>
    );
};

const SnippetForm: React.FC<{
    initialTitle: string;
    initialContent: string;
    onCancel: () => void;
    onSave: (title: string, content: string) => void;
}> = ({ initialTitle, initialContent, onCancel, onSave }) => {
    const [title, setTitle] = useState(initialTitle);
    const [content, setContent] = useState(initialContent);

    return (
        <div className="space-y-4">
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
                    onClick={() => onSave(title, content)}
                    disabled={!title || !content}
                    className="submit-btn"
                >
                    Save
                </button>
            </div>
        </div>
    )
}
