import { apiClient } from './core';

export const teamService = {
    /**
     * Invite a member to the team
     */
    inviteMember: async (email: string) => {
        return apiClient.request('/team/invite', {
            method: 'POST',
            body: JSON.stringify({ email })
        });
    },

    /**
     * Get list of team members
     */
    getMembers: async () => {
        return apiClient.request('/team/members');
    },

    /**
     * Get shared items (snippets or dictionary)
     */
    getSharedItems: async (type: 'snippets' | 'dictionary') => {
        return apiClient.request(`/team/shared/${type}`);
    },

    /**
     * Update shared items
     */
    updateSharedItems: async (type: 'snippets' | 'dictionary', data: any[]) => {
        return apiClient.request(`/team/shared/${type}`, {
            method: 'POST',
            body: JSON.stringify({ type, data })
        });
    }
};
