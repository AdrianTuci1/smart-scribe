import { ipcMain } from 'electron'
import { showWaveformWindow } from '../windows/waveformWindow'

export const registerWindowHandlers = (): void => {
    ipcMain.handle('open-waveform', () => {
        showWaveformWindow()
    })

    ipcMain.on('transcript-created', (_event, data) => {
        const { getMainWindow } = require('../protocol/deepLinkHandler')
        const mainWindow = getMainWindow()
        if (mainWindow) {
            mainWindow.webContents.send('transcript-created', data)
        }
    })
}
