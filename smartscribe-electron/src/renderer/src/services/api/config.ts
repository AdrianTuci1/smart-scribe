import { apiClient } from './core';

export const configService = {
    // Dictionary
    getDictionary: async (params?: { page?: number, limit?: number, search?: string, sort?: string }): Promise<{ data: any[], meta?: any }> => {
        const query = new URLSearchParams(params as any).toString();
        const res = await apiClient.request<{ data: any[], meta?: any }>(`/config/dictionary?${query}`);
        const list = res.data || [];
        const data = list.map(item => ({
            id: item.id || crypto.randomUUID(),
            incorrectWord: item.incorrectWord || item.incorrect_word || '',
            correctWord: item.correctWord || item.correct_word || ''
        }));
        return { data, meta: res.meta };
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

    addDictionaryEntry: async (entry: any): Promise<void> => {
        // Map camelCase to snake_case if backend expects it?
        // ConfigController uses Map.get(entry, "incorrectWord") so camelCase is fine if sent as such.
        // Wait, saving sends snake_case in saveDictionary.
        // But ConfigController.filter uses incorrectWord.
        // Let's verify standard.
        // BedrockClient.extract_rules checks both.
        // I will send valid object.
        return apiClient.request<void>('/config/dictionary/add', {
            method: 'POST',
            body: JSON.stringify({ entry })
        });
    },

    updateDictionaryEntry: async (entry: any): Promise<void> => {
        return apiClient.request<void>('/config/dictionary/update', {
            method: 'POST',
            body: JSON.stringify({ entry })
        });
    },

    deleteDictionaryEntry: async (id: string): Promise<void> => {
        return apiClient.request<void>(`/config/dictionary/${id}`, {
            method: 'DELETE'
        });
    },

    // Snippets
    getSnippets: async (params?: { page?: number, limit?: number, search?: string, sort?: string }): Promise<{ data: any[], meta?: any }> => {
        const query = new URLSearchParams(params as any).toString();
        const res = await apiClient.request<{ data: any[], meta?: any }>(`/config/snippets?${query}`);
        const list = res.data || [];
        const data = list.map(item => ({
            id: item.id || crypto.randomUUID(),
            title: item.title || '',
            content: item.content || ''
        }));
        return { data, meta: res.meta };
    },

    saveSnippets: async (snippets: any[]): Promise<void> => {
        return apiClient.request<void>('/config/snippets/save', {
            method: 'POST',
            body: JSON.stringify({ snippets })
        });
    },

    addSnippet: async (snippet: any): Promise<void> => {
        return apiClient.request<void>('/config/snippets/add', {
            method: 'POST',
            body: JSON.stringify({ snippet })
        });
    },

    updateSnippet: async (snippet: any): Promise<void> => {
        return apiClient.request<void>('/config/snippets/update', {
            method: 'POST',
            body: JSON.stringify({ snippet })
        });
    },

    deleteSnippet: async (id: string): Promise<void> => {
        return apiClient.request<void>(`/config/snippets/${id}`, {
            method: 'DELETE'
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
        return res.data; // Return raw data (null or object), do not default to {}
    },

    updateOnboarding: async (data: any): Promise<void> => {
        return apiClient.request<void>('/config/onboarding', {
            method: 'POST',
            body: JSON.stringify(data)
        });
    }
};
