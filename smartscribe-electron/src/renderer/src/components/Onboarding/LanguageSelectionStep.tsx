import React, { useState, useMemo } from 'react';
import { OnboardingLayout } from './OnboardingLayout';
import { Plus, Search, Minus, X } from 'lucide-react';
import './LanguageSelectionStep.css';

interface LanguageSelectionStepProps {
    onNext: () => void;
    onBack?: () => void;
    currentStep?: number;
    totalSteps?: number;
}

const LANGUAGES = [
    { id: 'en', label: 'English', flag: '🇺🇸' },
    { id: 'cmn', label: 'Mandarin (Simplified)', flag: '🇨🇳' },
    { id: 'es', label: 'Spanish', flag: '🇪🇸' },
    { id: 'af', label: 'Afrikaans', flag: '🇿🇦' },
    { id: 'sq', label: 'Albanian', flag: '🇦🇱' },
    { id: 'am', label: 'Amharic', flag: '🇪🇹' },
    { id: 'ar', label: 'Arabic', flag: '🇸🇦' },
    { id: 'hy', label: 'Armenian', flag: '🇦🇲' },
    { id: 'as', label: 'Assamese', flag: '🇮🇳' },
    { id: 'az', label: 'Azerbaijani', flag: '🇦🇿' },
    { id: 'ba', label: 'Bashkir', flag: '🇷🇺' },
    { id: 'eu', label: 'Basque', flag: '🇪🇸' },
    { id: 'be', label: 'Belarusian', flag: '🇧🇾' },
    { id: 'bn', label: 'Bengali', flag: '🇮🇳' },
    { id: 'bs', label: 'Bosnian', flag: '🇧🇦' },
    { id: 'br', label: 'Breton', flag: '🇫🇷' },
    { id: 'bg', label: 'Bulgarian', flag: '🇧🇬' },
    { id: 'yue', label: 'Cantonese', flag: '🇭🇰' },
    { id: 'ca', label: 'Catalan', flag: '🇪🇸' },
    { id: 'hr', label: 'Croatian', flag: '🇭🇷' },
    { id: 'cs', label: 'Czech', flag: '🇨🇿' },
    { id: 'da', label: 'Danish', flag: '🇩🇰' },
    { id: 'nl', label: 'Dutch', flag: '🇳🇱' },
    { id: 'et', label: 'Estonian', flag: '🇪🇪' },
    { id: 'fi', label: 'Finnish', flag: '🇫🇮' },
    { id: 'fr', label: 'French', flag: '🇫🇷' },
    { id: 'gl', label: 'Galician', flag: '🇪🇸' },
    { id: 'ka', label: 'Georgian', flag: '🇬🇪' },
    { id: 'de', label: 'German', flag: '🇩🇪' },
    { id: 'el', label: 'Greek', flag: '🇬🇷' },
    { id: 'gu', label: 'Gujarati', flag: '🇮🇳' },
    { id: 'ha', label: 'Hausa', flag: '🇳🇬' },
    { id: 'he', label: 'Hebrew', flag: '🇮🇱' },
    { id: 'hi', label: 'Hindi', flag: '🇮🇳' },
    { id: 'hu', label: 'Hungarian', flag: '🇭🇺' },
    { id: 'is', label: 'Icelandic', flag: '🇮🇸' },
    { id: 'id', label: 'Indonesian', flag: '🇮🇩' },
    { id: 'it', label: 'Italian', flag: '🇮🇹' },
    { id: 'ja', label: 'Japanese', flag: '🇯🇵' },
    { id: 'jw', label: 'Javanese', flag: '🇮🇩' },
    { id: 'kn', label: 'Kannada', flag: '🇮🇳' },
    { id: 'kk', label: 'Kazakh', flag: '🇰🇿' },
    { id: 'km', label: 'Khmer', flag: '🇰🇭' },
    { id: 'ko', label: 'Korean', flag: '🇰🇷' },
    { id: 'lo', label: 'Lao', flag: '🇱🇦' },
    { id: 'la', label: 'Latin', flag: '🇻🇦' },
    { id: 'lv', label: 'Latvian', flag: '🇱🇻' },
    { id: 'lt', label: 'Lithuanian', flag: '🇱🇹' },
    { id: 'mk', label: 'Macedonian', flag: '🇲🇰' },
    { id: 'ms', label: 'Malay', flag: '🇲🇾' },
    { id: 'ml', label: 'Malayalam', flag: '🇮🇳' },
    { id: 'mt', label: 'Maltese', flag: '🇲🇹' },
    { id: 'mi', label: 'Maori', flag: '🇳🇿' },
    { id: 'mr', label: 'Marathi', flag: '🇮🇳' },
    { id: 'mn', label: 'Mongolian', flag: '🇲🇳' },
    { id: 'ne', label: 'Nepali', flag: '🇳🇵' },
    { id: 'no', label: 'Norwegian', flag: '🇳🇴' },
    { id: 'oc', label: 'Occitan', flag: '🇫🇷' },
    { id: 'fa', label: 'Persian', flag: '🇮🇷' },
    { id: 'pl', label: 'Polish', flag: '🇵🇱' },
    { id: 'pt', label: 'Portuguese', flag: '🇵🇹' },
    { id: 'pa', label: 'Punjabi', flag: '🇮🇳' },
    { id: 'ro', label: 'Romanian', flag: '🇷🇴' },
    { id: 'ru', label: 'Russian', flag: '🇷🇺' },
    { id: 'sa', label: 'Sanskrit', flag: '🇮🇳' },
    { id: 'gd', label: 'Scots Gaelic', flag: '🏴󠁧󠁢󠁳󠁣󠁴󠁿' },
    { id: 'sr', label: 'Serbian', flag: '🇷🇸' },
    { id: 'sd', label: 'Sindhi', flag: '🇵🇰' },
    { id: 'si', label: 'Sinhala', flag: '🇱🇰' },
    { id: 'sk', label: 'Slovak', flag: '🇸🇰' },
    { id: 'sl', label: 'Slovenian', flag: '🇸🇮' },
    { id: 'so', label: 'Somali', flag: '🇸🇴' },
    { id: 'su', label: 'Sundanese', flag: '🇮🇩' },
    { id: 'sw', label: 'Swahili', flag: '🇰🇪' },
    { id: 'sv', label: 'Swedish', flag: '🇸🇪' },
    { id: 'tl', label: 'Tagalog', flag: '🇵🇭' },
    { id: 'tg', label: 'Tajik', flag: '🇹🇯' },
    { id: 'ta', label: 'Tamil', flag: '🇮🇳' },
    { id: 'tt', label: 'Tatar', flag: '🇷🇺' },
    { id: 'te', label: 'Telugu', flag: '🇮🇳' },
    { id: 'th', label: 'Thai', flag: '🇹🇭' },
    { id: 'tr', label: 'Turkish', flag: '🇹🇷' },
    { id: 'uk', label: 'Ukrainian', flag: '🇺🇦' },
    { id: 'ur', label: 'Urdu', flag: '🇵🇰' },
    { id: 'uz', label: 'Uzbek', flag: '🇺🇿' },
    { id: 'vi', label: 'Vietnamese', flag: '🇻🇳' },
    { id: 'cy', label: 'Welsh', flag: '🏴󠁧󠁢󠁷󠁬󠁳󠁿' },
    { id: 'yi', label: 'Yiddish', flag: '🇮🇱' },
    { id: 'yo', label: 'Yoruba', flag: '🇳🇬' }
];


export const LanguageSelectionStep: React.FC<LanguageSelectionStepProps> = ({
    onNext,
    onBack,
    currentStep,
    totalSteps
}) => {
    const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set(['en']));
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [searchQuery, setSearchQuery] = useState('');
    const [autoDetect, setAutoDetect] = useState(false);

    const toggleLanguage = (id: string) => {
        setSelectedIds(prev => {
            const next = new Set(prev);
            if (next.has(id)) {
                // Prevent removing if it's the only one? Or allow empty?
                // Usually allow removing unless it's the last one, but requirement says "English selected implicit".
                // Let's allow removing if user wants, but maybe prompt if empty.
                // For now, allow simple toggle.
                next.delete(id);
            } else {
                next.add(id);
            }
            return next;
        });
    };

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

    const VisualCard = (
        <div className="language-visual-card">
            <h3 className="language-visual-title">Your selected language</h3>
            <div className="selected-languages-display">
                <div className="language-tag-group">
                    {selectedLanguages.map(lang => (
                        <div key={lang.id} className="language-pill">
                            <span>{lang.label}</span>
                        </div>
                    ))}
                    <button className="add-language-btn-small" onClick={() => setIsModalOpen(true)}>
                        <Plus size={16} />
                    </button>
                </div>
            </div>
            <div className="language-card-actions">
                <button className="change-lang-btn" onClick={() => setIsModalOpen(true)}>
                    Change languages
                </button>
                <button className="continue-lang-btn" onClick={onNext}>
                    Continue
                </button>
            </div>
        </div>
    );

    return (
        <>
            <OnboardingLayout
                currentStep={currentStep}
                totalSteps={totalSteps}
                showVisual={true}
                visualContent={VisualCard}
            >
                <div className="language-selection-container">
                    <button
                        className="back-button-simple"
                        onClick={onBack}
                        style={{
                            alignSelf: 'flex-start',
                            background: 'none',
                            border: 'none',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '8px',
                            color: '#6b7280',
                            cursor: 'pointer',
                            marginBottom: '24px',
                            fontSize: '14px'
                        }}
                    >
                        ← Back
                    </button>

                    <h1 className="language-step-title">Set the language(s) you speak</h1>
                    <p className="language-step-subtitle">Smartscribe works in 100+ languages.</p>
                    <p className="language-step-description">
                        Select all the languages you speak or let Smartscribe detect them automatically.
                    </p>
                </div>
            </OnboardingLayout>

            {isModalOpen && (
                <div className="language-modal-overlay" onClick={(e) => {
                    if (e.target === e.currentTarget) setIsModalOpen(false);
                }}>
                    <div className="language-modal">
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
                                            onClick={() => toggleLanguage(lang.id)}
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
                                                onClick={() => toggleLanguage(lang.id)}
                                            >
                                                <Minus size={14} />
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>

                        <div className="modal-footer">
                            <button className="save-close-btn" onClick={() => setIsModalOpen(false)}>
                                Save and close
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
};
