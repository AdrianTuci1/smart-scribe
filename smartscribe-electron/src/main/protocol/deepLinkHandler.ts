import { app, BrowserWindow } from 'electron'
import { resolve } from 'path'
import { getWaveformWindow } from '../windows/waveformWindow'

export const registerProtocol = (): void => {
    if (process.defaultApp) {
        if (process.argv.length >= 2) {
            app.setAsDefaultProtocolClient('smartscribe', process.execPath, [resolve(process.argv[1])])
        }
    } else {
        app.setAsDefaultProtocolClient('smartscribe')
    }
}

export const setupSingleInstanceLock = (onSecondInstance: (url?: string) => void): boolean => {
    const gotTheLock = app.requestSingleInstanceLock()

    if (!gotTheLock) {
        app.quit()
        return false
    }

    app.on('second-instance', (_event, commandLine) => {
        const url = commandLine.find((arg) => arg.startsWith('smartscribe://'))
        onSecondInstance(url)
    })

    return true
}

export const setupMacOSProtocolHandler = (onOpenUrl: (url: string) => void): void => {
    app.on('open-url', (event, url) => {
        event.preventDefault()
        onOpenUrl(url)
    })
}

export const getMainWindow = (): BrowserWindow | undefined => {
    const waveformWindow = getWaveformWindow()
    return BrowserWindow.getAllWindows().find(w => !w.isDestroyed() && w !== waveformWindow)
}
