import { ipcMain, globalShortcut, BrowserWindow, app } from 'electron'
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

        // Handle Launch at Login
        if (key === 'launchAtLogin') {
            app.setLoginItemSettings({
                openAtLogin: value,
                path: app.getPath('exe')
            });
        }

        if (key === 'pushToTalkKey' || key === 'handsFreeModeKey') {
            updateGlobalShortcuts()
        }

        // Broadcast setting change
        BrowserWindow.getAllWindows().forEach(win => {
            win.webContents.send('setting-changed', key, value);
        });
    })

    ipcMain.handle('get-all-settings', () => {
        return (store as any).store
    })

    ipcMain.handle('reset-settings', () => {
        (store as any).clear();
        // Reset Launch at Login to default (true)
        app.setLoginItemSettings({
            openAtLogin: true,
            path: app.getPath('exe')
        });

        // Broadcast that settings have been reset? Or just let frontend re-fetch.
        // Better to broadcast specific keys or a 'settings-reset'? 
        // For now, let's just let the frontend logic (which called this) handle the UI update.
        // But other windows might need to know.
        BrowserWindow.getAllWindows().forEach(win => {
            // We could send individual defaults or a mass update. 
            // Simplest is to emit 'setting-changed' for critical ones or a new event.
            // We'll trust that the main window handles its own state, and we'll emit 'setting-changed' for flow bar
            win.webContents.send('setting-changed', 'showFlowBarAlways', true);
            win.webContents.send('setting-changed', 'pushToTalkKey', 'Fn');
        });
    })

    ipcMain.on('set-shortcut-recording-state', (_event, isRecording) => {
        BrowserWindow.getAllWindows().forEach(win => {
            win.webContents.send('shortcut-recording-state-changed', isRecording);
        });
    })
}

export const initializeGlobalShortcuts = (): void => {
    updateGlobalShortcuts()
}
