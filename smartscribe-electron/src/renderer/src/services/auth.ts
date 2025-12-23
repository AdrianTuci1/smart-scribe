import { apiService } from './api';

export interface User {
    id: string;
    email: string;
    username: string;
}

class AuthService {
    private static instance: AuthService;
    private user: User | null = null;
    private isAuthenticated: boolean = false;

    private constructor() {
        // Hydrate from storage if token exists
        if (localStorage.getItem('auth_token')) {
            this.isAuthenticated = true;
            // Ideally fetch user profile here
        }
    }

    public static getInstance(): AuthService {
        if (!AuthService.instance) {
            AuthService.instance = new AuthService();
        }
        return AuthService.instance;
    }

    public async login(username: string, password: string): Promise<User> {
        try {
            const response = await apiService.login({ username, password }) as any;
            // Adapt response based on actual API shape
            // For now assuming response.data contains token
            const token = response.data?.access_token || response.access_token; // Adjust based on direct response or wrapper
            if (token) {
                apiService.setToken(token);
                this.isAuthenticated = true;
                this.user = { id: 'temp', username, email: username }; // creating temp user
                return this.user!;
            }
            throw new Error('No token in response');
        } catch (error) {
            console.error('Login failed', error);
            throw error;
        }
    }

    public logout() {
        apiService.setToken(null);
        this.isAuthenticated = false;
        this.user = null;
        window.location.reload(); // Simple way to reset state
    }

    public isLoggedIn(): boolean {
        return this.isAuthenticated;
    }
}

export const authService = AuthService.getInstance();
