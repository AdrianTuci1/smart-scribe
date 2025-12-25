export interface Snippet {
    id: string;
    title: string;
    content: string;
}

export interface Transcript {
    id: string;
    text: string;
    timestamp: string; // ISO date string
    isFlagged: boolean;
    canUndoAIEdit: boolean;
    audioUrl?: string;
    duration?: number;
}

export interface DictionaryEntry {
    id: string;
    incorrectWord: string;
    correctWord: string;
}

export interface Note {
    id: string;
    content: string;
    createdAt: string;
    updatedAt: string;
}

export enum WritingStyle {
    VeryCasual = 'Very Casual',
    Casual = 'Casual',
    Formal = 'Formal'
}

export enum MessageContext {
    PersonalMessages = 'Personal Messages',
    WorkMessages = 'Work Messages',
    Email = 'Email',
    Other = 'Other'
}
