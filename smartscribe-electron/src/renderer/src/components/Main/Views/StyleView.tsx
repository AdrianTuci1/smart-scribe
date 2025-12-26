
import React, { useState, useEffect } from 'react';
import { MessageContext, WritingStyle } from '../../../types';
import { apiService } from '../../../services/api';
import { MessageCircle, Mail, Send, MoreHorizontal, Info, Loader2 } from 'lucide-react';
import clsx from 'clsx';
import './StyleView.css';

export const StyleView: React.FC = () => {
    const [selectedContext, setSelectedContext] = useState<MessageContext>(MessageContext.PersonalMessages);
    const [preferences, setPreferences] = useState<Record<MessageContext, WritingStyle>>({
        [MessageContext.PersonalMessages]: WritingStyle.VeryCasual,
        [MessageContext.WorkMessages]: WritingStyle.Casual,
        [MessageContext.Email]: WritingStyle.Formal,
        [MessageContext.Other]: WritingStyle.Casual
    });
    const [isLoading, setIsLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);

    // Load preferences from API
    useEffect(() => {
        const loadPreferences = async () => {
            setIsLoading(true);
            try {
                const data = await apiService.getStylePreferences();
                if (data && data.preferences) {
                    setPreferences(data.preferences);
                }
            } catch (error) {
                console.error('Failed to load style preferences', error);
                // Keep default preferences on error
            } finally {
                setIsLoading(false);
            }
        };

        loadPreferences();
    }, []);

    const currentStyle = preferences[selectedContext] || WritingStyle.Casual;

    const handleSelectStyle = async (style: WritingStyle) => {
        const newPreferences = {
            ...preferences,
            [selectedContext]: style
        };

        // Optimistic update
        setPreferences(newPreferences);
        setIsSaving(true);

        try {
            await apiService.updateStylePreferences({ preferences: newPreferences });
        } catch (error) {
            console.error('Failed to save style preferences', error);
            // Revert on error
            setPreferences(preferences);
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <div className="style-container scrollbar-hide">
            <div className="style-content">
                {/* Header */}
                <div className="mb-8">
                    <h1 className="style-title">Style</h1>

                    {/* Tabs */}
                    <div className="style-tabs">
                        {Object.values(MessageContext).map((context, i) => (
                            <button
                                key={context}
                                onClick={() => setSelectedContext(context)}
                                className={clsx(
                                    "style-tab-btn",
                                    selectedContext === context && "active"
                                )}
                                disabled={isLoading}
                            >
                                {context}
                                {selectedContext === context && (
                                    <div className="tab-indicator" />
                                )}
                            </button>
                        ))}
                    </div>

                    {/* Info Banner */}
                    <div className="info-banner">
                        <div className="info-icons">
                            <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/1200px-WhatsApp.svg.png" className="info-icon-base icon-whatsapp" alt="" />
                            <div className="info-icon-base icon-blue">
                                <MessageCircle size={16} fill="currentColor" />
                            </div>
                            <div className="info-icon-base icon-lightblue">
                                <Send size={16} fill="currentColor" />
                            </div>
                        </div>
                        <div>
                            <p className="info-text-primary">This style applies in {selectedContext.toLowerCase()}</p>
                            <p className="info-text-secondary">Available on desktop in English. iOS and more languages coming soon</p>
                        </div>
                    </div>
                </div>

                {/* Loading State */}
                {isLoading ? (
                    <div className="loading-container" style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '200px' }}>
                        <Loader2 className="loading-spinner" size={24} style={{ animation: 'spin 1s linear infinite' }} />
                    </div>
                ) : (
                    /* Style Options */
                    <div className="style-grid">
                        {Object.values(WritingStyle).map(style => (
                            <StyleOptionCard
                                key={style}
                                style={style}
                                isSelected={currentStyle === style}
                                onSelect={() => handleSelectStyle(style)}
                                disabled={isSaving}
                            />
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

const StyleOptionCard: React.FC<{
    style: WritingStyle;
    isSelected: boolean;
    onSelect: () => void;
    disabled?: boolean;
}> = ({ style, isSelected, onSelect, disabled = false }) => {

    const getExample = (s: WritingStyle) => {
        switch (s) {
            case WritingStyle.Formal: return "I would appreciate if you could review the attached document.";
            case WritingStyle.Casual: return "Hey, could you take a look at the doc I sent?";
            case WritingStyle.VeryCasual: return "Yo check the doc plz";
        }
    };

    const getAvatarClass = (s: WritingStyle) => {
        switch (s) {
            case WritingStyle.Formal: return "avatar-formal";
            case WritingStyle.Casual: return "avatar-casual";
            case WritingStyle.VeryCasual: return "avatar-very-casual";
        }
    };

    return (
        <div
            onClick={disabled ? undefined : onSelect}
            className={clsx(
                "style-card",
                isSelected && "selected",
                disabled && "opacity-50 cursor-not-allowed"
            )}
        >
            <div>
                <h3 className="card-title">{style === WritingStyle.VeryCasual ? "very casual" : style + "."}</h3>
                <p className="card-subtitle">
                    {style === WritingStyle.Formal ? "Caps + Punctuation" : style === WritingStyle.Casual ? "Caps + Less punctuation" : "No Caps + Less punctuation"}
                </p>
            </div>

            <div className="example-bubble">
                <p className="example-text">
                    {getExample(style)}
                </p>
            </div>

            <div className="card-footer">
                <div className={clsx("card-avatar", getAvatarClass(style))}>
                    J
                </div>
            </div>
        </div>
    );
}
