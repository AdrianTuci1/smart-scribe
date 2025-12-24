import React from 'react';
import './ResearchArticle.css';

const VoiceHabitsArticle = () => {
    return (
        <main className="research-section">
            <article className="research-article">
                <header className="article-header">
                    <span className="article-date">November 2025</span>
                    <h1 className="article-title">Building Trust Through Voice: How Smartscribe Creates Lasting Habits</h1>
                    <p className="article-intro">
                        Our goal at Smartscribe is to make interacting with your devices feel as effortless as talking to a close friend. We want people to have a voice interface that they trust, that's capable, and that really understands them on the first try.
                    </p>
                </header>

                <div className="article-content">
                    <p>
                        Smartscribe's approach to building voice interfaces is centered around creating sticky habits that fit seamlessly into people's lives — this is absolutely necessary to build interfaces that stick and avoid the pitfalls of companies that have tried and failed to build voice assistants. Our platform focuses on voice transcription and dictation for this reason: it's sticky. People type dozens of times a day on their devices - when we can speak, in place of typing, it creates an incredibly powerful habit.
                    </p>
                    <p>
                        For Smartscribe, our primary goal is to build habits and trust. We already see this happening — our median user starts to speak more and more to their devices, to the point where voice becomes their preferred input method. We're able to start breaking the mental model that voice doesn't work, and give users something that is reliable on the first try.
                    </p>

                    <section className="article-section">
                        <h2>From one habit to many workflows</h2>
                        <p>
                            As we build this habit and user trust, we want to expand Smartscribe into a tool that people can use for all of the ways in which they create content and communicate. We can go from building the one habit that people do dozens of times a day, to the 10 things they do 10 times a day, and eventually support the 100 things people might do once a week.
                        </p>
                        <p>
                            We plan to start by solving the workflows that people do frequently. Here are some examples we're exploring:
                        </p>
                    </section>

                    <section className="article-section">
                        <h3>Sending messages in the background</h3>
                        <p>
                            Ever opened your messaging app to send a quick note, see 20 unread messages, and immediately forget what you planned to do? That happens constantly. Voice interactions make this intuitive and straightforward - but to make this work, it has to succeed on the first try. If it fails even 20% of the time, users won't trust it enough to build the habit.
                        </p>
                    </section>

                    <section className="article-section">
                        <h3>Polishing and editing what people write</h3>
                        <p>
                            One of the most common use cases for AI tools is to copy-paste text, dictate edits, go back and forth to improve it, and finally use it. This workflow breaks your flow and is such a primitive way to use AI. We want all of these workflows to be embedded right in a user's natural process, and to be personalized to the way in which they communicate - no more generic AI output.
                        </p>
                    </section>

                    <section className="article-section">
                        <h3>Asking questions without context switching</h3>
                        <p>
                            In the middle of work and want to understand some terms in the context of what you're reading? Get a cryptic message? On a UI that's confusing that you don't know how to navigate? Why switch apps — voice interaction right where you are can make using your computer feel frictionless.
                        </p>
                    </section>

                    <section className="article-section">
                        <h3>Communicating without speaking precisely</h3>
                        <p>
                            So many times, we know what we want to say, but not quite how to say it. This might take a little bit of back and forth with a tool to help craft your brilliant idea into a usable piece of communication, but finally lets you share your insight with the world.
                        </p>
                    </section>

                    <section className="article-section">
                        <h3>Communication coaching</h3>
                        <p>
                            So many people have the goal of upleveling their communication at any given time — and better communication makes people more effective and fulfilled across the board. Given we integrate right into how people communicate, Smartscribe can help people get the outcomes they want from what they're sharing.
                        </p>
                    </section>

                    <section className="article-section">
                        <h2>Focus on what matters</h2>
                        <p>
                            There are countless ways people want to use voice interfaces — these are just five of the hundreds of workflows we've identified.
                        </p>
                        <p>
                            You'll notice we skipped the most common demo of a voice assistant: booking travel or ordering food with voice. We've seen those demos before, and while they seem impressive, they're not particularly useful. People book flights occasionally, and using voice doesn't make the workflow significantly faster. Instead, we focus on workflows that people repeat many times a day, and where our understanding of how people want to communicate allows us to build a better product.
                        </p>
                    </section>

                    <section className="article-section article-conclusion">
                        <h2>Reimagining how we interact with technology</h2>
                        <p>
                            When we look at people interacting with their devices today, what we see is effort, strain, distraction, and lack of presence. It's cumbersome. There's so much context switching. Software grabs our attention and distracts us. It's so far from how we relate to the people around us.
                        </p>
                        <p>
                            Smartscribe is building toward a future where technology feels less like a barrier and more like a natural extension of how we think and communicate. By focusing on trust, habits, and workflows that matter, we're creating voice interfaces that people actually want to use — not just once, but every single day.
                        </p>
                    </section>
                </div>
            </article>
        </main>
    );
};

export default VoiceHabitsArticle;
