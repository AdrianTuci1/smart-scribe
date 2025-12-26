import { BrowserWindow } from 'electron'
import { join } from 'path'

let isQuitting = false

export const setIsQuitting = (value: boolean) => {
    isQuitting = value
}

export const createMainWindow = (): BrowserWindow => {
    const mainWindow = new BrowserWindow({
        width: 900,
        height: 670,
        minWidth: 800,
        minHeight: 600,
        show: false,
        frame: false,
        titleBarStyle: 'hidden',
        trafficLightPosition: { x: 20, y: 18 },
        transparent: true,
        vibrancy: 'under-window',
        visualEffectState: 'active',
        autoHideMenuBar: true,
        webPreferences: {
            preload: join(__dirname, '../preload/index.js'),
            sandbox: false
        }
    })

    mainWindow.on('ready-to-show', () => {
        mainWindow.show()
        mainWindow.webContents.openDevTools()
    })

    if (process.env['ELECTRON_RENDERER_URL']) {
        mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL'])
    } else {
        mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
    }

    mainWindow.on('close', (event) => {
        if (!isQuitting) {
            event.preventDefault()
            mainWindow.hide()
        }
        return false
    })

    return mainWindow
}
