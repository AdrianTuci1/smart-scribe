import { apiClient } from './core';

export interface TicketPayload {
    message: string;
    email?: string;
    type?: 'support' | 'feedback' | 'bug';
}

export const supportService = {
    sendTicket: async (payload: TicketPayload): Promise<void> => {
        // Map 'type' to 'subject' as backend expects 'subject'
        const backendPayload = {
            subject: payload.type ? `[${payload.type.toUpperCase()}] Support Request` : 'General Support',
            message: payload.message,
            userId: 'current-user-id-injected-by-backend' // Backend likely inspects token
        };
        return apiClient.request<void>('/support/ticket', {
            method: 'POST',
            body: JSON.stringify(backendPayload)
        });
    },
};
