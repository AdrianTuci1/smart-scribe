import React from 'react';
import TryButton from './ui/TryButton';
import DownloadButton from './ui/DownloadButton';
import './TargetUsers.css';

const TargetUsers = () => {
    const users = ['Consultants', 'Creators', 'Engineers', 'Lawyers', 'Doctors', 'Scientists', 'Researchers', 'Teachers', 'Teams', 'Customer Support'];

    return (
        <section className="target-users">
            <div className="target-users-container">
                <div className="target-users-content">
                    <div className="target-users-left">
                        <span className="eyebrow">MADE FOR YOU</span>
                        <h2 className="target-users-title">
                            Write with <br /> your voice.
                        </h2>
                        <p className="target-users-description">
                            The ultimate shortcut for your thoughts. Transcribe smart live speech into structured content, giving you a faster way to write with the touch of a key. Quietly powerful. Naturally accurate.
                        </p>
                    </div>

                    <div className="target-users-right">
                        <div className="chips-container">
                            {users.map((user) => (
                                <span key={user} className="user-chip">
                                    {user}
                                </span>
                            ))}
                        </div>

                        <div className="target-users-actions">
                            <TryButton variant="outline-gray" className="action-btn" />
                            <DownloadButton variant="primary" className="action-btn" />
                        </div>
                    </div>
                </div>
            </div>
        </section>
    );
};

export default TargetUsers;
