import { useNavigate } from 'react-router-dom';

/*=============================================
=            Configuration            =
=============================================*/
export const API_CONFIG = {
    // VITE_API_BASE_URL should be set in .env similar to Electron
    // or fallback to localhost
    BASE_URL: import.meta.env.VITE_API_BASE_URL || (import.meta.env.PROD
        ? 'https://api.smartscribe.app/api/v1'
        : 'http://localhost:4000/api/v1')
};

// NOTE: Electron uses /api/v1 prefix in core.ts manually, but here I put it in base config for simplicity
// or I can match Electron style exactly. Electron has `BASE_URL: ...` then appends `/v1`.
// Let's match Electron structure to be safe with shared code if we copy-paste.
const BASE_URL_ROOT = import.meta.env.VITE_API_BASE_URL || (import.meta.env.PROD
    ? 'https://api.smartscribe.app/api'
    : 'http://localhost:4000/api');

/*=============================================
=            API Client Core          =
=============================================*/
class ApiClient {
    constructor() {
        this.token = null;
        this.baseUrl = `${BASE_URL_ROOT}/v1`;
    }

    static getInstance() {
        if (!ApiClient.instance) {
            ApiClient.instance = new ApiClient();
        }
        return ApiClient.instance;
    }

    setToken(token) {
        this.token = token;
        if (token) {
            localStorage.setItem('auth_token', token);
        } else {
            localStorage.removeItem('auth_token');
        }
    }

    getToken() {
        if (!this.token) {
            this.token = localStorage.getItem('auth_token');
        }
        return this.token;
    }

    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;

        const headers = {
            'Content-Type': 'application/json',
            ...(options.headers || {})
        };

        const token = this.getToken();
        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        const config = {
            ...options,
            headers
        };

        const response = await fetch(url, config);

        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`HTTP Error ${response.status}: ${errorBody}`);
        }

        if (response.status === 204) {
            return {};
        }

        try {
            return await response.json();
        } catch (e) {
            return {};
        }
    }
}

export const apiClient = ApiClient.getInstance();

/*=============================================
=            Subscription Service     =
=============================================*/
export const subscriptionService = {
    /**
     * Creates a Stripe Checkout Session for a subscription
     * @param {'monthly' | 'yearly'} plan 
     * @returns {Promise<{ url: string }>}
     */
    createCheckoutSession: async (plan) => {
        return apiClient.request('/subscriptions/checkout', {
            method: 'POST',
            body: JSON.stringify({ plan })
        });
    },

    /**
     * Creates a Stripe Customer Portal session
     * @returns {Promise<{ url: string }>}
     */
    createPortalSession: async () => {
        return apiClient.request('/subscriptions/portal', {
            method: 'POST'
        });
    }
};

/*=============================================
=            Config Service           =
=============================================*/
// Needed for checking onboarding/status potentially
export const configService = {
    getOnboarding: async () => {
        return apiClient.request('/config/onboarding');
    }
};
