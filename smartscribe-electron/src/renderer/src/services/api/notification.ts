
import { apiClient } from './core';

export interface NotificationItem {
    id: string; // This corresponds to configType technically, or we map it
    configType?: string; // We might need this explicitly
    title: string;
    message: string;
    type: 'team_invite' | 'system' | 'limit_reached';
    status: 'unread' | 'read' | 'actioned' | 'denied';
    createdAt: string;
    data?: any;
}

export const notificationService = {
    getAll: async (): Promise<NotificationItem[]> => {
        return apiClient.request('/notifications');
    },

    markRead: async (id: string) => {
        // id here should be the configType if that's what backend expects
        return apiClient.request(`/notifications/${encodeURIComponent(id)}/action`, {
            method: 'POST',
            body: JSON.stringify({ action: 'read' })
        });
    },

    respondToInvite: async (id: string, accept: boolean) => {
        return apiClient.request(`/notifications/${encodeURIComponent(id)}/action`, {
            method: 'POST',
            body: JSON.stringify({ action: accept ? 'accept' : 'deny' })
        });
    }
};
