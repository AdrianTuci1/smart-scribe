import React from 'react';
import './ResearchArticle.css';

const ResearchArticle = () => {
    return (
        <main className="research-section">
            <article className="research-article">
                <header className="article-header">
                    <span className="article-date">December 2025</span>
                    <h1 className="article-title">The Invisible Interface: How Smartscribe Rethinks Voice AI</h1>
                    <p className="article-intro">
                        We are at the beginning of a new interface era. But instead of seeing radical new forms, we see a strange recursion: AI tools wrapped in old patterns. Chatbots that mimic search boxes. Assistants that parrot human tone, not understanding. Sidebars full of toggles. Everywhere, AI is being bolted onto existing UI like an afterthought, and it shows.
                    </p>
                </header>

                <div className="article-content">
                    <p>
                        Smartscribe takes a different path. Instead of stacking AI on top of apps, we built it into the core experience. It doesn't demand new workflows, but enhances the ones you already have. It doesn't ask you to learn a new app. It works anywhere you work. You don't think about Smartscribe, you think with it in whatever app you are in.
                    </p>
                    <p>
                        This is not a coincidence. It is the result of a deep, deliberate design philosophy.
                    </p>

                    <section className="article-section">
                        <h2>Voice is invisible, and that's its superpower</h2>
                        <p>
                            Most software is visible. You see the button. You tap the input. Voice, by contrast, disappears. It is ambient, contextual, and ephemeral. That makes it uniquely powerful, but also uniquely hard to design for.
                        </p>
                        <p>
                            With Smartscribe, we embraced that invisibility. We didn't want users to speak into a void and hope it worked. We also didn't want to constantly flash an obstructive UI just to remind you it exists. So we found a balance: a subtle interface that signals availability without noise. Tiny detail, massive impact.
                        </p>
                        <p>
                            Designing invisible interfaces is not about being minimal. It's about simplifying complexity and being meaningful in the workflows that matter.
                        </p>
                    </section>

                    <section className="article-section">
                        <h2>Streaming vs. understanding</h2>
                        <p>
                            Traditional voice interfaces use Automatic Speech Recognition (ASR). They transcribe and stream real-time. Sure it's fast and immediate, but dumb. Words arrive as they're spoken, often wrong and overstimulating and jarring. More noise than signal.
                        </p>
                        <p>
                            Smartscribe does something different. We use large language models (LLMs) to post-process your speech. Which means Smartscribe can wait, understand, and then write what you meant. Not just what you said.
                        </p>
                        <p>
                            This is a subtle shift with radical implications. It allows Smartscribe to be less distracting while you're speaking. It gives it the ability to correct grammar, maintain tone, and even match your personal phrasing style over time. It makes the product feel intelligent and context-appropriate.
                        </p>
                        <p>
                            Streaming might give your writing speed, but Smartscribe gives it clarity and meaning. This is core to how people communicate asynchronously.
                        </p>
                    </section>

                    <section className="article-section">
                        <h2>Built at the OS layer, not the app layer</h2>
                        <p>
                            Smartscribe doesn't live inside one app. It's a layer that runs across them all: email, Slack, Notion, iMessage, ChatGPT, etc. This was a technical as well as a design decision.
                        </p>
                        <p>
                            Technically, it meant navigating complex system-level constraints around keyboard, microphone, and text input. Design-wise, it meant building interactions that feel native to the OS, not bolted on top.
                        </p>
                        <p>
                            The result? Smartscribe doesn't fight the platform. It flows with it.
                        </p>
                    </section>

                    <section className="article-section">
                        <h2>Designed to be forgotten</h2>
                        <p>
                            This might sound counterintuitive, but we don't want Smartscribe to be the thing on your mind all the time. We want the idea you spoke to be the thing you remember. Smartscribe should disappear into your muscle memory. That's how you change behavior at scale.
                        </p>
                        <p>
                            It's why we sweated the latency and the interaction. Why we optimized the hold-and-speak interaction. Why we prioritized responsiveness over visible feedback. It's also why Smartscribe feels more like a power you have, not a tool you use.
                        </p>
                    </section>

                    <section className="article-section article-conclusion">
                        <h2>Final thought: magic isn't flashy, it's frictionless.</h2>
                        <p>
                            Most AI products try to impress you with intelligence. Smartscribe tries to disappear. The true magic is not in what the product says – it's in what it lets you say, more naturally, and with less effort.
                        </p>
                        <p>
                            When the interface is invisible, intention becomes the input. That's what we're building: not just better voice dictation, but a new layer of computing that feels as natural as thought.
                        </p>
                    </section>
                </div>
            </article>
        </main>
    );
};

export default ResearchArticle;
