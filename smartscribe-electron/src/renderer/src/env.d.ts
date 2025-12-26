/// <reference types="vite/client" />

interface PermissionApi {
    checkAccessibility: () => Promise<boolean>;
    requestAccessibility: () => Promise<boolean>;
    checkMicrophone: () => Promise<string>;
    requestMicrophone: () => Promise<boolean>;
    resizeWindow: (width: number, height: number) => Promise<void>;
    openWaveform: () => Promise<void>;
    getSettings: (key: string) => Promise<any>;
    setSetting: (key: string, value: any) => Promise<void>;
    getAllSettings: () => Promise<any>;
}

interface ElectronApi {
    ipcRenderer: {
        send: (channel: string, data: any) => void;
        on: (channel: string, func: (...args: any[]) => void) => () => void;
        invoke: (channel: string, data?: any) => Promise<any>;
    } & PermissionApi;
}

declare global {
    interface Window {
        electron: ElectronApi;
    }
}

export { };
