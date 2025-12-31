// API Response Types
export interface ApiResponse<T> {
    success: boolean;
    data: T;
    message?: string;
}

// Style Preferences
export interface StylePreferencesData {
    preferences: Record<string, string>;
}

export interface StylePreferencesResponse extends ApiResponse<StylePreferencesData> { }

// User Stats
export interface UserStatsData {
    streak: number;
    totalWords: number;
    averageWpm: number;
    lastActiveDate?: string;
    totalTranscripts?: number;
}

export interface UserStatsResponse extends ApiResponse<UserStatsData> { }

// Transcripts
export interface TranscriptData {
    id: string;
    text?: string;
    timestamp: string;
    isFlagged: boolean;
    canUndoAIEdit: boolean;
    audioUrl?: string;
    duration?: number;
}

export interface TranscriptsResponse extends ApiResponse<TranscriptData[]> { }

export interface TranscriptResponse extends ApiResponse<TranscriptData> { }

// Dictionary
export interface DictionaryEntryData {
    id: string;
    incorrectWord: string;
    correctWord: string;
}

export interface DictionaryResponse extends ApiResponse<DictionaryEntryData[]> { }

// Notes
export interface NoteData {
    id: string;
    content: string;
    createdAt: string;
    updatedAt: string;
}

export interface NotesResponse extends ApiResponse<NoteData[]> { }

export interface NoteResponse extends ApiResponse<NoteData> { }

// Snippets
export interface SnippetData {
    id: string;
    title: string;
    content: string;
}

export interface SnippetsResponse extends ApiResponse<SnippetData[]> { }

// Settings
export interface SettingsData {
    [key: string]: any;
}

export interface SettingsResponse extends ApiResponse<SettingsData> { }

// Auth
export interface LoginData {
    token: string;
    user: {
        id: string;
        email: string;
        name?: string;
    };
}

export interface LoginResponse extends ApiResponse<LoginData> { }

export interface SignupResponse extends ApiResponse<LoginData> { }

// Error Response
export interface ApiError {
    success: false;
    message: string;
    errors?: Record<string, string[]>;
    statusCode?: number;
}
