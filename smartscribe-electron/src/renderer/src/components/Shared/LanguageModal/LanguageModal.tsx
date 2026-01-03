import React, { useState, useMemo } from 'react';
import { Search, Minus } from 'lucide-react';
import { LANGUAGES } from '../../../data/languages';
import './LanguageModal.css';

interface LanguageModalProps {
    isOpen: boolean;
    onClose: () => void;
    selectedIds: Set<string>;
    onToggle: (id: string) => void;
    onSave?: () => void;
    darkTheme?: boolean;
}

export const LanguageModal: React.FC<LanguageModalProps> = ({
    isOpen,
    onClose,
    selectedIds,
    onToggle,
    onSave,
    darkTheme = false
}) => {
    const [searchQuery, setSearchQuery] = useState('');
    const [autoDetect, setAutoDetect] = useState(false);

    const selectedLanguages = useMemo(() => {
        return LANGUAGES.filter(l => selectedIds.has(l.id));
    }, [selectedIds]);

    const filteredLanguages = useMemo(() => {
        if (!searchQuery) return LANGUAGES;
        const q = searchQuery.toLowerCase();
        return LANGUAGES.filter(l =>
            l.label.toLowerCase().includes(q)
        );
    }, [searchQuery]);

    const handleSave = () => {
        if (onSave) {
            onSave();
        }
        onClose();
    };

    if (!isOpen) return null;

    return (
        <div className="language-modal-overlay" onClick={(e) => {
            if (e.target === e.currentTarget) onClose();
        }}>
            <div className={`language-modal ${darkTheme ? 'dark' : ''}`}>
                <div className="modal-header">
                    <div className="modal-title-group">
                        <h2>Languages</h2>
                        <p className="modal-subtitle">Select the languages you want to use with Smartscribe</p>
                    </div>
                    <div className="auto-detect-group">
                        <span className="auto-detect-label">Auto-detect</span>
                        <label className="toggle-switch">
                            <input
                                type="checkbox"
                                checked={autoDetect}
                                onChange={(e) => setAutoDetect(e.target.checked)}
                            />
                            <span className="toggle-slider"></span>
                        </label>
                    </div>
                </div>

                <div className="modal-body">
                    {/* Left: Language List */}
                    <div className="language-list-section">
                        <div className="language-search-wrapper">
                            <Search className="search-icon" size={16} />
                            <input
                                type="text"
                                className="language-search"
                                placeholder="Search for any languages"
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                autoFocus
                            />
                        </div>
                        <div className="languages-grid">
                            {filteredLanguages.map(lang => (
                                <button
                                    key={lang.id}
                                    className={`language-option-btn ${selectedIds.has(lang.id) ? 'selected' : ''}`}
                                    onClick={() => onToggle(lang.id)}
                                >
                                    <span className="lang-flag">{lang.flag}</span>
                                    <span className="lang-name">{lang.label}</span>
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Right: Selected List */}
                    <div className="selected-side">
                        <div className="selected-header">Selected</div>
                        <div className="selected-list">
                            {selectedLanguages.map(lang => (
                                <div key={lang.id} className="selected-list-item">
                                    <div className="selected-item-info">
                                        <span className="lang-flag">{lang.flag}</span>
                                        <span className="lang-name">{lang.label}</span>
                                    </div>
                                    <button
                                        className="remove-lang-btn"
                                        onClick={() => onToggle(lang.id)}
                                    >
                                        <Minus size={14} />
                                    </button>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                <div className="modal-footer">
                    <button className="save-close-btn" onClick={handleSave}>
                        Save and close
                    </button>
                </div>
            </div>
        </div>
    );
};
