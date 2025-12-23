import React, { useEffect, useRef, useState } from 'react';

const SnippetItem = ({ text, delay, customStyle, isVisible }) => (
    <div
        style={{ '--delay': delay, ...customStyle }}
        className={`snippet-item ${isVisible ? 'snippet-item-visible' : 'snippet-item-hidden'}`}
    >
        <span className="snippet-text">{text}</span>
    </div>
);

const FeatureSnippets = () => {
    const containerRef = useRef(null);
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        const observer = new IntersectionObserver(
            ([entry]) => {
                setIsVisible(entry.isIntersecting);
            },
            {
                threshold: 0.2, // Trigger when 20% of component is visible
                rootMargin: '-50px'
            }
        );

        if (containerRef.current) {
            observer.observe(containerRef.current);
        }

        return () => {
            if (containerRef.current) {
                observer.unobserve(containerRef.current);
            }
        };
    }, []);

    return (
        <div className="feature-visual-container" ref={containerRef}>
            {/* Header */}
            <div className="feature-visual-header">
                <h3 className="feature-visual-title">Your Snippets</h3>
                <button className="feature-add-button">
                    +
                </button>
            </div>

            {/* List */}
            <div className="feature-list-container">
                <SnippetItem text="Calendar" delay="0s" customStyle={{ zIndex: 10, position: 'relative' }} isVisible={isVisible} />

                {/* Indented Message - Slides in like the others */}
                <div
                    style={{ '--delay': '0.1s', zIndex: 1, position: 'relative' }}
                    className={`snippet-indented-message ${isVisible ? 'snippet-item-visible' : 'snippet-item-hidden'}`}
                >
                    You can book a 30-minute call with me here: calendly.com/smartscribe
                </div>

                <SnippetItem text="Hours" delay="0.2s" isVisible={isVisible} />
                <SnippetItem text="Support intro" delay="0.3s" isVisible={isVisible} />
                <SnippetItem text="FAQ" delay="0.4s" isVisible={isVisible} />
                <div className="opacity-50" style={{ opacity: 0.5 }}>
                    <SnippetItem text="Careers link" delay="0.5s" isVisible={isVisible} />
                </div>
            </div>
            <div className="dictionary-fade-overlay"></div>
        </div>
    );
};

export default FeatureSnippets;
