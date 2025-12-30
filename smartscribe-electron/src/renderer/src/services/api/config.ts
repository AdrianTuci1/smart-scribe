import { apiClient } from './core';

export const configService = {
    // Dictionary
    getDictionary: async (): Promise<any[]> => {
        return apiClient.request<any[]>('/config/dictionary');
    },

    saveDictionary: async (entries: any[]): Promise<void> => {
        return apiClient.request<void>('/config/dictionary/save', {
            method: 'POST',
            body: JSON.stringify({ entries })
        });
    },

    // Snippets
    getSnippets: async (): Promise<any[]> => {
        return apiClient.request<any[]>('/config/snippets');
    },

    saveSnippets: async (snippets: any[]): Promise<void> => {
        return apiClient.request<void>('/config/snippets/save', {
            method: 'POST',
            body: JSON.stringify({ snippets })
        });
    },

    // Style Preferences
    getStylePreferences: async (): Promise<any> => {
        return apiClient.request<any>('/config/style_preferences');
    },

    saveStylePreferences: async (preferences: any): Promise<void> => {
        return apiClient.request<void>('/config/style_preferences/save', {
            method: 'POST',
            body: JSON.stringify(preferences)
        });
    },

    // Settings
    getSettings: async (): Promise<any> => {
        return apiClient.request<any>('/config/settings');
    },

    updateSettings: async (settings: any): Promise<void> => {
        return apiClient.request<void>('/config/settings', {
            method: 'POST',
            body: JSON.stringify(settings)
        });
    },

    // Onboarding (also in router.ex)
    getOnboarding: async (): Promise<any> => {
        // defaults: %{"type" => "onboarding"}
        return apiClient.request<any>('/config/onboarding');
    },

    updateOnboarding: async (data: any): Promise<void> => {
        return apiClient.request<void>('/config/onboarding', {
            method: 'POST',
            body: JSON.stringify(data)
        });
    }
};
