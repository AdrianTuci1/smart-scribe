
import React, { useState, useEffect, useRef } from 'react';
import { Bell } from 'lucide-react';
import { notificationService, NotificationItem } from '../../services/api';
import './NotificationBell.css';
import clsx from 'clsx';
import { formatDistanceToNow } from 'date-fns';

export const NotificationBell: React.FC = () => {
    const [isOpen, setIsOpen] = useState(false);
    const [notifications, setNotifications] = useState<NotificationItem[]>([]);
    const [unreadCount, setUnreadCount] = useState(0);
    const dropdownRef = useRef<HTMLDivElement>(null);

    // Close on click outside
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const fetchNotifications = async () => {
        try {
            const list = await notificationService.getAll();
            if (Array.isArray(list)) {
                // Backend sends items. We need to map `configType` to `id` if needed, 
                // or ensure backend sends `id` as `configType` or accessible.
                // Assuming list contains `configType`.
                const mapped = list.map(item => ({
                    ...item,
                    id: item.configType || item.id // Ensure we have the ID needed for actions
                }));
                // Sort by date desc
                mapped.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

                setNotifications(mapped);
                setUnreadCount(mapped.filter(n => n.status === 'unread').length);
            }
        } catch (e) {
            console.error("Failed to fetch notifications", e);
        }
    };

    useEffect(() => {
        fetchNotifications();
        // Poll every 30s? Or rely on manual refresh/events?
        const interval = setInterval(fetchNotifications, 30000);
        return () => clearInterval(interval);
    }, []);

    const handleAction = async (id: string, action: 'accept' | 'deny' | 'read') => {
        try {
            if (action === 'read') {
                await notificationService.markRead(id);
                // Optimistic update
                setNotifications(prev => prev.map(n => n.id === id ? { ...n, status: 'read' } : n));
                setUnreadCount(prev => Math.max(0, prev - 1));
            } else {
                await notificationService.respondToInvite(id, action === 'accept');
                // Optimistic update: mark as actioned
                setNotifications(prev => prev.map(n => n.id === id ? { ...n, status: action === 'accept' ? 'actioned' : 'denied' } : n));

                // If accepted, maybe trigger a refresh of TeamSettings or global state?
                // For now just visually update.
            }
        } catch (e) {
            console.error(e);
        }
    };

    const handleToggle = () => {
        if (!isOpen) {
            fetchNotifications(); // Refresh on open
        }
        setIsOpen(!isOpen);
    };

    return (
        <div className="notification-bell-container" ref={dropdownRef}>
            <button
                className={clsx("notification-bell-btn", isOpen && "active")}
                onClick={handleToggle}
            >
                <Bell size={20} />
                {unreadCount > 0 && (
                    <span className="notification-badge">{unreadCount > 9 ? '9+' : unreadCount}</span>
                )}
            </button>

            {isOpen && (
                <div className="notification-dropdown">
                    <div className="notification-header">
                        <h3>Notifications</h3>
                    </div>
                    <div className="notification-list scrollbar-hide">
                        {notifications.length === 0 ? (
                            <div className="empty-notifications">
                                <p>No notifications</p>
                            </div>
                        ) : (
                            notifications.map(notification => (
                                <NotificationItemRow
                                    key={notification.id}
                                    notification={notification}
                                    onAction={handleAction}
                                />
                            ))
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

const NotificationItemRow: React.FC<{
    notification: NotificationItem;
    onAction: (id: string, action: 'accept' | 'deny' | 'read') => void;
}> = ({ notification, onAction }) => {
    const isInvite = notification.type === 'team_invite';
    const isUnread = notification.status === 'unread';
    const isActioned = notification.status === 'actioned' || notification.status === 'denied';

    return (
        <div className={clsx("notification-item", isUnread && "unread")}>
            <div className="notification-icon">
                {isInvite ? '👥' : '🔔'}
            </div>
            <div className="notification-content">
                <p className="notification-title">{notification.title}</p>
                <p className="notification-msg">{notification.message}</p>
                <span className="notification-time">
                    {formatDistanceToNow(new Date(notification.createdAt), { addSuffix: true })}
                </span>

                {isInvite && !isActioned && (
                    <div className="notification-actions">
                        <button
                            className="btn-accept"
                            onClick={() => onAction(notification.id, 'accept')}
                        >
                            Accept
                        </button>
                        <button
                            className="btn-deny"
                            onClick={() => onAction(notification.id, 'deny')}
                        >
                            Deny
                        </button>
                    </div>
                )}
                {isInvite && isActioned && (
                    <p className="notification-status-text">
                        {notification.status === 'actioned' ? 'Accepted' : 'Denied'}
                    </p>
                )}
            </div>
            {isUnread && !isInvite && (
                <button className="btn-mark-read" onClick={() => onAction(notification.id, 'read')} title="Mark read">
                    •
                </button>
            )}
        </div>
    )
}
