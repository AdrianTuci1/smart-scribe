import { apiClient } from './core';

export const subscriptionService = {
    /**
     * Creates a Stripe Checkout Session for a subscription
     * @param plan 'monthly' | 'yearly'
     * @returns Promise with checkout session URL
     */
    createCheckoutSession: async (plan: 'monthly' | 'yearly'): Promise<{ url: string }> => {
        return apiClient.request('/subscriptions/checkout', {
            method: 'POST',
            body: JSON.stringify({ plan })
        });
    },

    /**
     * Creates a Stripe Customer Portal session for managing billing
     * @returns Promise with portal session URL
     */
    createPortalSession: async (): Promise<{ url: string }> => {
        return apiClient.request('/subscriptions/portal', {
            method: 'POST'
        });
    }
};
