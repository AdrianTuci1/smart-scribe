
import React, { useState } from 'react';
import { MessageContext, WritingStyle } from '../../../types';
import { MessageCircle, Mail, Send, MoreHorizontal, Info } from 'lucide-react';
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

    const currentStyle = preferences[selectedContext] || WritingStyle.Casual;

    const handleSelectStyle = (style: WritingStyle) => {
        setPreferences(prev => ({
            ...prev,
            [selectedContext]: style
        }));
        // TODO: Sync to backend if needed
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

                {/* Style Options */}
                <div className="style-grid">
                    {Object.values(WritingStyle).map(style => (
                        <StyleOptionCard
                            key={style}
                            style={style}
                            isSelected={currentStyle === style}
                            onSelect={() => handleSelectStyle(style)}
                        />
                    ))}
                </div>
            </div>
        </div>
    );
};

const StyleOptionCard: React.FC<{
    style: WritingStyle;
    isSelected: boolean;
    onSelect: () => void;
}> = ({ style, isSelected, onSelect }) => {

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
            onClick={onSelect}
            className={clsx(
                "style-card",
                isSelected && "selected"
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
