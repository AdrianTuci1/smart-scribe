import { API_CONFIG } from '../../config';

export class ApiClient {
    private static instance: ApiClient;
    private token: string | null = null;
    private baseUrl: string;

    private constructor() {
        // Ensure we point to /api/v1 as per router.ex
        // API_CONFIG.BASE_URL is typically '.../api'
        this.baseUrl = `${API_CONFIG.BASE_URL}/v1`;
    }

    public static getInstance(): ApiClient {
        if (!ApiClient.instance) {
            ApiClient.instance = new ApiClient();
        }
        return ApiClient.instance;
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

    public async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
        // Endpoint should start with /, e.g. /transcripts
        const url = `${this.baseUrl}${endpoint}`;

        const headers: HeadersInit = {
            'Content-Type': 'application/json',
            ...(options.headers || {})
        };

        const token = this.getToken();
        if (token) {
            (headers as any)['Authorization'] = `Bearer ${token}`;
        }

        const config: RequestInit = {
            ...options,
            headers
        };

        const response = await fetch(url, config);

        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`HTTP Error ${response.status}: ${errorBody}`);
        }

        // Some endpoints might return empty body (e.g. 204 No Content)
        if (response.status === 204) {
            return {} as T;
        }

        try {
            const data = await response.json();
            return data as T;
        } catch (e) {
            // Fallback if not JSON or empty
            return {} as T;
        }
    }
}

export const apiClient = ApiClient.getInstance();
