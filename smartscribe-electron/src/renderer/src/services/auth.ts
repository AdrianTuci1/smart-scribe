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
            const token = response.data?.access_token || response.access_token;
            if (token) {
                this.setSession(token, { id: 'temp', username, email: username });
                return this.user!;
            }
            throw new Error('No token in response');
        } catch (error) {
            console.error('Login failed', error);
            throw error;
        }
    }

    public async signInWithWebBrowser() {
        // Construct the login URL. Replace with your actual auth provider URL.
        const authUrl = 'https://your-auth-domain.com/login?redirect_uri=voicescribe://auth/callback';
        // In a real app, you might fetch this from config or API
        if ((window as any).electron) {
            await (window as any).electron.ipcRenderer.invoke('open-external', authUrl);
        } else {
            console.warn('Electron not available, cannot open external URL');
            window.open(authUrl, '_blank');
        }
    }

    public async handleAuthCallback(url: string): Promise<boolean> {
        try {
            const urlObj = new URL(url);

            // Check scheme and path
            if (urlObj.protocol !== 'voicescribe:' || (!urlObj.pathname.includes('callback') && !urlObj.host.includes('auth'))) {
                return false;
            }

            const params = new URLSearchParams(urlObj.search);
            const token = params.get('access_token') || params.get('token');

            if (token) {
                // In production, you might want to fetch user profile here
                this.setSession(token, { id: 'user_from_callback', username: 'User', email: 'user@example.com' });
                return true;
            }

            return false;
        } catch (error) {
            console.error('Error handling auth callback:', error);
            return false;
        }
    }

    private setSession(token: string, user: User) {
        apiService.setToken(token);
        localStorage.setItem('auth_token', token);
        this.isAuthenticated = true;
        this.user = user;
    }

    public logout() {
        apiService.setToken(null);
        this.isAuthenticated = false;
        this.user = null;
        window.location.reload();
    }

    public isLoggedIn(): boolean {
        return this.isAuthenticated;
    }
}

export const authService = AuthService.getInstance();
