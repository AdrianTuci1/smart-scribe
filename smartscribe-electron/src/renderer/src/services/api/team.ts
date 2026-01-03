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
    getSharedItems: async (type: 'snippets' | 'dictionary', params?: { page?: number, limit?: number, search?: string, sort?: string }): Promise<{ data: any[], meta?: any }> => {
        const query = new URLSearchParams(params as any).toString();
        return apiClient.request<{ data: any[], meta?: any }>(`/team/shared/${type}?${query}`);
    },

    /**
     * Update shared items (Legacy)
     */
    updateSharedItems: async (type: 'snippets' | 'dictionary', data: any[]) => {
        return apiClient.request(`/team/shared/${type}`, {
            method: 'POST',
            body: JSON.stringify({ type, data })
        });
    },

    /**
     * Granular Team Add
     */
    addSharedItem: async (type: 'snippets' | 'dictionary', item: any) => {
        return apiClient.request(`/team/shared/${type}/add`, {
            method: 'POST',
            body: JSON.stringify({ type, item })
        });
    },

    updateSharedItem: async (type: 'snippets' | 'dictionary', item: any) => {
        return apiClient.request(`/team/shared/${type}/update`, {
            method: 'POST',
            body: JSON.stringify({ type, item })
        });
    },

    deleteSharedItem: async (type: 'snippets' | 'dictionary', id: string) => {
        return apiClient.request(`/team/shared/${type}/${id}`, {
            method: 'DELETE'
        });
    }
};
