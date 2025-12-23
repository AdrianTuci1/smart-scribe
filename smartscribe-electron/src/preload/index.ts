import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('electron', {
    ipcRenderer: {
        send: (channel: string, data: any) => ipcRenderer.send(channel, data),
        on: (channel: string, func: (...args: any[]) => void) => {
            const subscription = (_event: any, ...args: any[]) => func(...args)
            ipcRenderer.on(channel, subscription)

            return () => ipcRenderer.removeListener(channel, subscription)
        },
        invoke: (channel: string, data?: any) => ipcRenderer.invoke(channel, data),

        // Permission APIs
        checkAccessibility: () => ipcRenderer.invoke('check-accessibility'),
        requestAccessibility: () => ipcRenderer.invoke('request-accessibility'),
        checkMicrophone: () => ipcRenderer.invoke('check-microphone'),
        requestMicrophone: () => ipcRenderer.invoke('request-microphone'),
        resizeWindow: (width: number, height: number) => ipcRenderer.invoke('resize-window', width, height),
        openWaveform: () => ipcRenderer.invoke('open-waveform'),
        getSettings: (key: string) => ipcRenderer.invoke('get-settings', key),
        setSetting: (key: string, value: any) => ipcRenderer.invoke('set-setting', key, value),
        getAllSettings: () => ipcRenderer.invoke('get-all-settings')
    }
})
