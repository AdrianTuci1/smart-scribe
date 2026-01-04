import { apiClient } from './core';
import { Note } from '../../types';

export const notesService = {
    getAll: async (params?: { page?: number, limit?: number, search?: string, sort?: string }): Promise<{ data: Note[], meta?: any }> => {
        const query = new URLSearchParams(params as any).toString();
        const res = await apiClient.request<{ data: any[], meta?: any }>(`/notes?${query}`);
        const notes = res.data || [];
        const data = notes.map(n => ({
            id: n.noteId || n.id, // Support noteId from backend or id fallback
            content: n.content,
            timestamp: n.timestamp,
            createdAt: n.timestamp || new Date().toISOString(),
            updatedAt: n.timestamp || new Date().toISOString()
        }));
        return { data, meta: res.meta };
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

    update: async (note: { id: string; content: string }): Promise<Note> => {
        const payload = {
            content: note.content,
            timestamp: new Date().toISOString()
        };
        const res = await apiClient.request<{ data: any }>(`/notes/${note.id}`, {
            method: 'PUT',
            body: JSON.stringify(payload)
        });
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
