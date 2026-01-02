import { apiClient, configService } from './api';
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const POOL_DATA = {
    UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
    ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID
};

const COGNITO_DOMAIN = import.meta.env.VITE_COGNITO_DOMAIN;
const REDIRECT_URI = import.meta.env.VITE_COGNITO_REDIRECT_URI || window.location.origin;
// fallback to origin if not set usually works if callback handles it, but better be exact.
// In this case we probably need a dedicated callback page or handling in main app.

class AuthService {
    constructor() {
        this.userPool = new CognitoUserPool(POOL_DATA);
        this.user = null;
        this.isAuthenticated = false;
        this.checkCurrentSession();
    }

    static getInstance() {
        if (!AuthService.instance) {
            AuthService.instance = new AuthService();
        }
        return AuthService.instance;
    }

    async checkCurrentSession() {
        // 1. Check SDK Session
        const cognitoUser = this.userPool.getCurrentUser();
        if (cognitoUser != null) {
            cognitoUser.getSession((err, session) => {
                if (err) {
                    console.error('Session error:', err);
                    this.logout();
                    return;
                }
                if (session.isValid()) {
                    this.handleSession(session, cognitoUser);
                }
            });
        } else {
            // 2. Check LocalStorage Manual Session (Social Login)
            const token = localStorage.getItem('auth_token');
            const idToken = localStorage.getItem('id_token');
            if (token && idToken) {
                try {
                    const payload = JSON.parse(atob(idToken.split('.')[1]));
                    const now = Math.floor(Date.now() / 1000);
                    if (payload.exp && payload.exp < now) {
                        this.logout();
                        return;
                    }

                    apiClient.setToken(token);
                    this.isAuthenticated = true;

                    const name = payload.name || payload.given_name || payload['cognito:username'] || payload.email;
                    this.user = {
                        id: payload.sub,
                        email: payload.email,
                        username: name
                    };
                } catch (e) {
                    this.logout();
                }
            }
        }
    }

    handleSession(session, cognitoUser) {
        const accessToken = session.getAccessToken().getJwtToken();
        apiClient.setToken(accessToken);
        this.isAuthenticated = true;

        cognitoUser.getUserAttributes((err, attributes) => {
            if (err) return;

            const emailAttr = attributes?.find(attr => attr.getName() === 'email');
            const subAttr = attributes?.find(attr => attr.getName() === 'sub');
            const nameAttr = attributes?.find(attr => attr.getName() === 'name');

            const displayName = nameAttr?.getValue() || cognitoUser.getUsername();
            const finalName = (!nameAttr && emailAttr) ? emailAttr.getValue().split('@')[0] : displayName;

            this.user = {
                id: subAttr ? subAttr.getValue() : 'unknown',
                email: emailAttr ? emailAttr.getValue() : cognitoUser.getUsername(),
                username: finalName
            };
        });
    }

    async login(email, password) {
        return new Promise((resolve, reject) => {
            const authDetails = new AuthenticationDetails({
                Username: email,
                Password: password,
            });

            const cognitoUser = new CognitoUser({
                Username: email,
                Pool: this.userPool,
            });

            cognitoUser.authenticateUser(authDetails, {
                onSuccess: (result) => {
                    this.handleSession(result, cognitoUser);
                    resolve(this.user);
                },
                onFailure: (err) => {
                    reject(err);
                },
                newPasswordRequired: () => {
                    reject(new Error('New password required - not supported in this UI'));
                }
            });
        });
    }

    async signInWithGoogle() {
        const clientId = POOL_DATA.ClientId;
        // Construct the hosted UI URL
        const redirect = encodeURIComponent(REDIRECT_URI);
        // Note: REDIRECT_URI must match exactly what's permitted in Cognito Console!

        const authUrl = `${COGNITO_DOMAIN}/oauth2/authorize?identity_provider=Google&response_type=code&client_id=${clientId}&redirect_uri=${redirect}&scope=email+openid+profile`;

        window.location.href = authUrl;
    }

    async handleAuthCallback(code) {
        try {
            const tokenUrl = `${COGNITO_DOMAIN}/oauth2/token`;
            const clientId = POOL_DATA.ClientId;
            // Must use same redirect URI as request
            const redirect = REDIRECT_URI;

            const response = await fetch(tokenUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: new URLSearchParams({
                    grant_type: 'authorization_code',
                    client_id: clientId,
                    code: code,
                    redirect_uri: redirect
                })
            });

            if (response.ok) {
                const data = await response.json();

                apiClient.setToken(data.access_token);
                this.isAuthenticated = true;

                const payload = JSON.parse(atob(data.id_token.split('.')[1]));
                let name = payload.name || payload.given_name || payload.email.split('@')[0];

                this.user = {
                    id: payload.sub,
                    email: payload.email,
                    username: name
                };

                localStorage.setItem('auth_token', data.access_token);
                localStorage.setItem('id_token', data.id_token);

                return true;
            }
        } catch (error) {
            console.error('Callback error:', error);
        }
        return false;
    }

    logout() {
        const cognitoUser = this.userPool.getCurrentUser();
        if (cognitoUser) {
            cognitoUser.signOut();
        }
        apiClient.setToken(null);
        this.isAuthenticated = false;
        this.user = null;
        localStorage.removeItem('auth_token');
        localStorage.removeItem('id_token');
        window.location.reload();
    }

    isLoggedIn() {
        return this.isAuthenticated;
    }

    getUser() {
        return this.user;
    }
}

export const authService = AuthService.getInstance();
