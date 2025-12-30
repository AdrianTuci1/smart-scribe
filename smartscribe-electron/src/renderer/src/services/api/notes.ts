import { apiClient } from './core';
import { Note } from '../../types';

export const notesService = {
    getAll: async (): Promise<Note[]> => {
        return apiClient.request<Note[]>('/notes');
    },

    create: async (note: Omit<Note, 'id' | 'createdAt' | 'updatedAt'>): Promise<Note> => {
        // Backend likely assigns ID and timestamps
        return apiClient.request<Note>('/notes', {
            method: 'POST',
            body: JSON.stringify(note)
        });
    },

    delete: async (id: string): Promise<void> => {
        return apiClient.request<void>(`/notes/${id}`, {
            method: 'DELETE'
        });
    }
};
