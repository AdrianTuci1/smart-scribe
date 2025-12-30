import { ipcMain, globalShortcut, BrowserWindow } from 'electron'
import Store from 'electron-store'

const store = new Store()

const updateGlobalShortcuts = () => {
    globalShortcut.unregisterAll()

    const pushToTalkKey = (store as any).get('pushToTalkKey') as string
    const handsFreeKey = (store as any).get('handsFreeModeKey') as string

    if (pushToTalkKey) {
        // Skip registration for Fn key as it's handled by Swift key monitor
        if (pushToTalkKey === 'Fn') {
            console.log('Skipping standard global registration for Fn key (handled by monitor)');
        } else {
            try {
                const accelerator = pushToTalkKey.replace('Cmd', 'Command')
                globalShortcut.register(accelerator, () => {
                    const wins = BrowserWindow.getAllWindows()
                    wins.forEach(w => w.webContents.send('shortcut-triggered', 'pushToTalk'))
                    console.log('Push to Talk Triggered')
                })
            } catch (e) {
                console.error(`Failed to register shortcut ${pushToTalkKey}`, e)
            }
        }
    }

    if (handsFreeKey) {
        try {
            const accelerator = handsFreeKey.replace('Cmd', 'Command')
            globalShortcut.register(accelerator, () => {
                const wins = BrowserWindow.getAllWindows()
                wins.forEach(w => w.webContents.send('shortcut-triggered', 'handsFree'))
                console.log('Hands Free Triggered')
            })
        } catch (e) {
            console.error(`Failed to register shortcut ${handsFreeKey}`, e)
        }
    }
}

export const registerSettingsHandlers = (): void => {
    ipcMain.handle('get-settings', (_event, key) => {
        return (store as any).get(key)
    })

    ipcMain.handle('set-setting', (_event, key, value) => {
        (store as any).set(key, value)

        if (key === 'pushToTalkKey' || key === 'handsFreeModeKey') {
            updateGlobalShortcuts()
        }
    })

    ipcMain.handle('get-all-settings', () => {
        return (store as any).store
    })
}

export const initializeGlobalShortcuts = (): void => {
    updateGlobalShortcuts()
}
