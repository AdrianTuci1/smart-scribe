import { API_CONFIG } from '../config';

class ApiService {
    private static instance: ApiService;
    private token: string | null = null;

    private constructor() { }

    public static getInstance(): ApiService {
        if (!ApiService.instance) {
            ApiService.instance = new ApiService();
        }
        return ApiService.instance;
    }

    public setToken(token: string | null) {
        this.token = token;
        if (token) {
            localStorage.setItem('auth_token', token);
        } else {
            localStorage.removeItem('auth_token');
        }
    }

    public getToken(): string | null {
        if (!this.token) {
            this.token = localStorage.getItem('auth_token');
        }
        return this.token;
    }

    private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
        const url = `${API_CONFIG.BASE_URL}${endpoint}`;

        const headers: HeadersInit = {
            'Content-Type': 'application/json',
            ...(options.headers || {})
        };

        const token = this.getToken();
        if (token) {
            (headers as any)['Authorization'] = `Bearer ${token}`; // specific cast to allow Authorization key
        }

        const config: RequestInit = {
            ...options,
            headers
        };

        const response = await fetch(url, config);

        if (!response.ok) {
            // Handle HTTP errors
            const errorBody = await response.text();
            throw new Error(`HTTP Error ${response.status}: ${errorBody}`);
        }

        const data = await response.json();
        return data as T;
    }

    // Auth
    public async login(data: any) {
        return this.request('/auth/login', {
            method: 'POST',
            body: JSON.stringify(data)
        });
    }

    public async signup(data: any) {
        return this.request('/auth/signup', {
            method: 'POST',
            body: JSON.stringify(data)
        });
    }

    // Transcripts
    public async getTranscripts(): Promise<any[]> { // Replace any with Transcript[] when imported
        return this.request('/transcripts');
    }

    public async updateTranscript(transcript: any): Promise<any> {
        return this.request(`/transcripts/${transcript.id}`, {
            method: 'PUT',
            body: JSON.stringify(transcript)
        });
    }

    public async deleteTranscript(id: string): Promise<void> {
        return this.request(`/transcripts/${id}`, {
            method: 'DELETE'
        });
    }

    public async retryTranscription(id: string): Promise<any> {
        return this.request(`/transcripts/${id}/retry`, {
            method: 'POST'
        });
    }

    // Dictionary
    public async getDictionary(): Promise<any[]> {
        return this.request('/dictionary');
    }

    public async syncDictionary(entries: any[]): Promise<void> {
        return this.request('/dictionary/sync', {
            method: 'POST',
            body: JSON.stringify({ entries })
        });
    }

    // Notes
    public async getNotes(): Promise<any[]> {
        return this.request('/notes');
    }

    public async syncNote(note: any): Promise<any> {
        return this.request('/notes', {
            method: 'POST',
            body: JSON.stringify(note)
        });
    }

    // Snippets
    public async getSnippets(): Promise<any[]> {
        return this.request('/snippets');
    }

    public async syncSnippets(snippets: any[]): Promise<void> {
        return this.request('/snippets/sync', {
            method: 'POST',
            body: JSON.stringify({ snippets })
        });
    }

    // Config
    public async getSettings() {
        return this.request('/config/settings');
    }

    // Style Preferences
    public async getStylePreferences(): Promise<any> {
        return this.request('/user/style-preferences');
    }

    public async updateStylePreferences(preferences: any): Promise<void> {
        return this.request('/user/style-preferences', {
            method: 'PUT',
            body: JSON.stringify(preferences)
        });
    }

    // User Stats
    public async getUserStats(): Promise<any> {
        return this.request('/user/stats');
    }

    // Audio Download
    public async downloadAudio(transcriptId: string): Promise<Blob> {
        const url = `${API_CONFIG.BASE_URL}/transcripts/${transcriptId}/audio`;
        const token = this.getToken();

        const headers: HeadersInit = {};
        if (token) {
            (headers as any)['Authorization'] = `Bearer ${token}`;
        }

        const response = await fetch(url, { headers });

        if (!response.ok) {
            throw new Error(`Failed to download audio: ${response.status}`);
        }

        return response.blob();
    }
}

export const apiService = ApiService.getInstance();
