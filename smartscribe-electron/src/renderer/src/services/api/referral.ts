import { apiClient } from './core';

interface ReferralInfo {
    referralCode: string;
    referralLink: string;
    totalReferrals: number;
    earnedMonths: number;
}

export const referralService = {
    getReferralInfo: async (): Promise<ReferralInfo> => {
        return apiClient.request('/referral');
    }
};
