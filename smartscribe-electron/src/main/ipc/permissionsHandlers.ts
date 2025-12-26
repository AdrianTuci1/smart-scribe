import { ipcMain, systemPreferences } from 'electron'

export const registerPermissionsHandlers = (): void => {
    ipcMain.handle('check-accessibility', () => {
        if (process.platform === 'darwin') {
            return systemPreferences.isTrustedAccessibilityClient(false)
        }
        return true
    })

    ipcMain.handle('request-accessibility', () => {
        if (process.platform === 'darwin') {
            return systemPreferences.isTrustedAccessibilityClient(true)
        }
        return true
    })

    ipcMain.handle('check-microphone', () => {
        if (process.platform === 'darwin') {
            return systemPreferences.getMediaAccessStatus('microphone')
        }
        return 'granted'
    })

    ipcMain.handle('request-microphone', async () => {
        if (process.platform === 'darwin') {
            return await systemPreferences.askForMediaAccess('microphone')
        }
        return true
    })

    ipcMain.handle('check-permissions', () => {
        const micStatus = process.platform === 'darwin'
            ? systemPreferences.getMediaAccessStatus('microphone')
            : 'granted'

        const accessibilityStatus = process.platform === 'darwin'
            ? systemPreferences.isTrustedAccessibilityClient(false)
            : true

        return {
            microphone: micStatus,
            accessibility: accessibilityStatus
        }
    })
}
