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

    // Notes
    public async getNotes() {
        return this.request('/notes');
    }

    // Config
    public async getSettings() {
        return this.request('/config/settings');
    }

    // Add more methods as needed mirroring Swift
}

export const apiService = ApiService.getInstance();
