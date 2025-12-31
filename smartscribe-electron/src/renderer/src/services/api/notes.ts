import { apiClient } from './core';
import { Note } from '../../types';

export const notesService = {
    getAll: async (): Promise<Note[]> => {
        const res = await apiClient.request<{ data: any[] }>('/notes');
        const notes = res.data || [];
        return notes.map(n => ({
            id: n.noteId || n.id, // Support noteId from backend or id fallback
            content: n.content,
            timestamp: n.timestamp,
            createdAt: n.timestamp || new Date().toISOString(),
            updatedAt: n.timestamp || new Date().toISOString()
        }));
    },

    create: async (note: Omit<Note, 'id' | 'createdAt' | 'updatedAt' | 'timestamp'>): Promise<Note> => {
        // Backend expects arbitrary params. We send content.
        const payload = {
            content: note.content,
            timestamp: new Date().toISOString()
        };
        const res = await apiClient.request<{ data: any }>('/notes', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
        // Map response back
        const data = res.data || {};
        return {
            id: data.noteId || data.id,
            content: data.content,
            timestamp: data.timestamp,
            createdAt: data.timestamp || new Date().toISOString(),
            updatedAt: data.timestamp || new Date().toISOString()
        };
    },

    delete: async (id: string): Promise<void> => {
        return apiClient.request<void>(`/notes/${id}`, {
            method: 'DELETE'
        });
    }
};
