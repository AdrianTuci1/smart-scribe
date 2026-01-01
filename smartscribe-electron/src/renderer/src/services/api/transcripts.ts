import { apiClient } from './core';
import { Transcript } from '../../types';

export const transcriptService = {
    getAll: async (): Promise<Transcript[]> => {
        const res = await apiClient.request<{ data: any[] }>('/transcripts');
        console.log('API /transcripts response:', res);
        const list = res.data || [];
        console.log('Parsed transcripts list:', list);
        return list.map(t => ({
            ...t,
            id: t.transcriptId || t.id,
            timestamp: t.createdAt || t.timestamp,
            text: t.text || t.enhancedText || t.originalText || ''
        }));
    },

    getById: async (id: string): Promise<Transcript> => {
        const res = await apiClient.request<{ data: Transcript }>(`/transcripts/${id}`);
        return res.data;
    },

    create: async (data: Partial<Transcript>): Promise<Transcript> => {
        const res = await apiClient.request<{ data: Transcript }>('/transcripts', {
            method: 'POST',
            body: JSON.stringify(data)
        });
        return res.data;
    },

    update: async (transcript: Partial<Transcript> & { id: string }): Promise<Transcript> => {
        const res = await apiClient.request<{ data: Transcript }>(`/transcripts/${transcript.id}`, {
            method: 'PUT',
            body: JSON.stringify(transcript)
        });
        return res.data;
    },

    delete: async (id: string): Promise<void> => {
        return apiClient.request<void>(`/transcripts/${id}`, {
            method: 'DELETE'
        });
    },

    retry: async (id: string): Promise<any> => {
        return apiClient.request<any>(`/transcripts/${id}/retry`, {
            method: 'POST'
        });
    },

    getAudioUrl: async (id: string): Promise<string> => {
        // This endpoint returns a JSON with { url: "..." } or similar
        // Based on router.ex: get("/transcripts/:id/audio", ...)
        // Let's assume it returns { url: string }
        const res = await apiClient.request<{ url: string }>(`/transcripts/${id}/audio`);
        return res.url;
    },

    // Keeping download logic similar to original but using core if possible
    // The original downloadAudio returned a Blob. The router says :audio_url which suggests it returns a URL?
    // Let's check router.ex again. 
    // get("/transcripts/:id/audio", TranscriptsController, :audio_url)
    // Usually :audio_url implies getting a signed URL.
    // However, the original code did a fetch to /audio and returned response.blob().
    // If the backend has changed to return a URL, we should adapt.
    // If it streams audio, we keep blob.
    // For now, I will implement a method that matches the OLD behavior but using the NEW path structure, 
    // UNLESS the name :audio_url strongly implies otherwise.
    // Given the user said "ensure valid communication", I will trust the ROUTER naming more.
    // If it is :audio_url, it likely returns a JSON struct.
    // Use raw request for blob download if needed.

    downloadAudioBlob: async (id: string): Promise<Blob> => {
        // First get the URL from the backend
        const { url } = await apiClient.request<{ url: string }>(`/transcripts/${id}/audio`);

        // Then fetch the actual audio file
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Failed to download audio: ${response.status}`);
        }
        return response.blob();
    }
};
