import { ipcMain } from 'electron'
import { showWaveformWindow } from '../windows/waveformWindow'

export const registerWindowHandlers = (): void => {
    ipcMain.handle('open-waveform', () => {
        showWaveformWindow()
    })
}
