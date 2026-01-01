import { apiClient } from './core';

export const configService = {
    // Dictionary
    getDictionary: async (): Promise<any[]> => {
        const res = await apiClient.request<{ data: any[] }>('/config/dictionary');
        const list = res.data || [];
        return list.map(item => ({
            id: item.id || crypto.randomUUID(),
            incorrectWord: item.incorrectWord || item.incorrect_word || '',
            correctWord: item.correctWord || item.correct_word || ''
        }));
    },

    saveDictionary: async (entries: any[]): Promise<void> => {
        const payload = entries.map(entry => ({
            id: entry.id,
            incorrect_word: entry.incorrectWord,
            correct_word: entry.correctWord
        }));
        return apiClient.request<void>('/config/dictionary/save', {
            method: 'POST',
            body: JSON.stringify({ dictionary: { entries: payload } })
        });
    },

    // Snippets
    getSnippets: async (): Promise<any[]> => {
        const res = await apiClient.request<{ data: any[] }>('/config/snippets');
        const list = res.data || [];
        return list.map(item => ({
            id: item.id || crypto.randomUUID(),
            title: item.title || '',
            content: item.content || ''
        }));
    },

    saveSnippets: async (snippets: any[]): Promise<void> => {
        return apiClient.request<void>('/config/snippets/save', {
            method: 'POST',
            body: JSON.stringify({ snippets })
        });
    },

    // Style Preferences
    getStylePreferences: async (): Promise<any> => {
        const res = await apiClient.request<{ data: any }>('/config/style_preferences');
        return res.data || {};
    },

    saveStylePreferences: async (preferences: any): Promise<void> => {
        return apiClient.request<void>('/config/style_preferences/save', {
            method: 'POST',
            body: JSON.stringify(preferences)
        });
    },

    // Settings
    getSettings: async (): Promise<any> => {
        const res = await apiClient.request<{ data: any }>('/config/settings');
        return res.data || {};
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
        const res = await apiClient.request<{ data: any }>('/config/onboarding');
        return res.data || {};
    },

    updateOnboarding: async (data: any): Promise<void> => {
        return apiClient.request<void>('/config/onboarding', {
            method: 'POST',
            body: JSON.stringify(data)
        });
    }
};
