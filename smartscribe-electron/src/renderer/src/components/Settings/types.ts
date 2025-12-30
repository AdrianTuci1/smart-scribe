export type SettingsCategory =
    | 'general'
    | 'system'
    | 'vibeCoding'
    | 'experimental'
    | 'account'
    | 'team'
    | 'plansBilling'
    | 'dataPrivacy';

export interface UserSettings {
    // General
    pushToTalkKey: string;
    handsFreeModeKey: string;
    commandModeEnabled: boolean;
    pasteLastTranscriptEnabled: boolean;
    selectedMicrophone: string;
    selectedLanguage: string;

    // System
    launchAtLogin: boolean;
    showFlowBarAlways: boolean;
    showInDock: boolean;
    dictationSoundEffect: boolean;
    muteMusicWhileDictating: boolean;
    autoAddToDirectory: boolean;
    smartFormatting: boolean;
    emailAutoSignature: boolean;
    creatorMode: boolean;

    // Vibe Coding
    variableRecognition: boolean;
    fileTaggingInChat: boolean;

    // Experimental
    advancedVoiceCommands: boolean;

    // Data & Privacy
    privacyMode: boolean;
    contextAwareness: boolean;
    hipaaEnabled: boolean;
}

export const defaultSettings: UserSettings = {
    pushToTalkKey: 'Fn',
    handsFreeModeKey: 'Cmd+Shift+H',
    commandModeEnabled: false,
    pasteLastTranscriptEnabled: true,
    selectedMicrophone: 'Auto Detect',
    selectedLanguage: 'English (US)',
    launchAtLogin: false,
    showFlowBarAlways: false,
    showInDock: true,
    dictationSoundEffect: true,
    muteMusicWhileDictating: false,
    autoAddToDirectory: false,
    smartFormatting: true,
    emailAutoSignature: false,
    creatorMode: false,
    variableRecognition: false,
    fileTaggingInChat: false,
    advancedVoiceCommands: false,
    privacyMode: false,
    contextAwareness: true,
    hipaaEnabled: false,
};

export interface SettingsTabProps {
    settings: UserSettings;
    onSettingChange: (key: keyof UserSettings, value: any) => void;
}
