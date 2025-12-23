export const API_CONFIG = {
    BASE_URL: 'http://localhost:4000/api/v1', // From Swift config
    COGNITO: {
        REGION: 'eu-central-1',
        USER_POOL_ID: 'eu-central-1_KUaE0MTcQ',
        CLIENT_ID: 'ar2m2qg3gp4a0b4cld09aegdb',
        DOMAIN: 'https://auth.simplu.io',
        REDIRECT_URI: 'smartscribe://auth' // Changed protocol to match potential deep link
    }
};
