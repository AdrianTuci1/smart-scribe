import React, { useState, useEffect } from 'react';
import { X, Send, CheckCircle, Loader2 } from 'lucide-react';
import { supportService } from '../../services/api';
import { apiService } from '../../services/api'; // For getToken
import './TicketModal.css';

interface TicketModalProps {
    isOpen: boolean;
    onClose: () => void;
    prefillEmail?: string;
}

export const TicketModal: React.FC<TicketModalProps> = ({ isOpen, onClose, prefillEmail }) => {
    const [message, setMessage] = useState('');
    // email state logic: 
    // If prefillEmail is provided, use it.
    // If NOT provided, check if user is logged in (token exists) -> maybe we can get email from profile?
    // But for now, if not provided, let user type it.
    const [email, setEmail] = useState(prefillEmail || '');
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [isSuccess, setIsSuccess] = useState(false);
    const [error, setError] = useState<string | null>(null);

    // Effect to update email if prefill changes or to check auth when opening
    useEffect(() => {
        if (isOpen) {
            setMessage('');
            setIsSuccess(false);
            setError(null);
            if (prefillEmail) {
                setEmail(prefillEmail);
            }
        }
    }, [isOpen, prefillEmail]);

    if (!isOpen) return null;

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!message.trim()) return;
        if (!email.trim()) {
            setError('Please enter your email so we can reply.');
            return;
        }

        setIsSubmitting(true);
        setError(null);

        try {
            await supportService.sendTicket({
                message,
                email,
                type: 'support'
            });
            setIsSuccess(true);
            setTimeout(() => {
                onClose();
                setIsSuccess(false);
            }, 2000);
        } catch (err: any) {
            console.error('Failed to send ticket:', err);
            setError('Failed to send message. Please try again.');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="ticket-modal-overlay" onClick={onClose}>
            <div className="ticket-modal" onClick={e => e.stopPropagation()}>
                <div className="ticket-modal-header">
                    <h2>Contact Support</h2>
                    <button className="close-button" onClick={onClose}>
                        <X size={20} />
                    </button>
                </div>

                {isSuccess ? (
                    <div className="ticket-modal-body">
                        <div className="success-message">
                            <CheckCircle size={20} />
                            <span>Message sent! We'll get back to you shortly.</span>
                        </div>
                    </div>
                ) : (
                    <form className="ticket-modal-body" onSubmit={handleSubmit}>
                        <div className="ticket-input-group">
                            <label>Email</label>
                            <input
                                type="email"
                                className="ticket-input"
                                placeholder="name@example.com"
                                value={email}
                                onChange={e => setEmail(e.target.value)}
                                required
                            />
                        </div>

                        <div className="ticket-input-group">
                            <label>How can we help?</label>
                            <textarea
                                className="ticket-textarea"
                                placeholder="Describe your issue or question..."
                                value={message}
                                onChange={e => setMessage(e.target.value)}
                                required
                            />
                        </div>

                        {error && <div style={{ color: '#ef4444', fontSize: '13px' }}>{error}</div>}

                        <div className="ticket-modal-footer">
                            <button type="button" className="cancel-button" onClick={onClose}>
                                Cancel
                            </button>
                            <button
                                type="submit"
                                className="send-ticket-button"
                                disabled={isSubmitting || !message.trim() || !email.trim()}
                            >
                                {isSubmitting ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
                                Send
                            </button>
                        </div>
                    </form>
                )}
            </div>
        </div>
    );
};
