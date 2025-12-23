import { app, BrowserWindow, Tray, Menu, nativeImage } from 'electron'
import { join } from 'path'
import Store from 'electron-store'

const store = new Store()

let tray: Tray | null = null

let isQuitting = false

const createWindow = () => {
    const mainWindow = new BrowserWindow({
        width: 600,
        height: 500,
        show: false,
        frame: false, // frameless
        titleBarStyle: 'hiddenInset', // macOS style
        autoHideMenuBar: true,
        webPreferences: {
            preload: join(__dirname, '../preload/index.js'),
            sandbox: false
        }
    })

    mainWindow.on('ready-to-show', () => {
        mainWindow.show()
        // Open DevTools for debugging
        mainWindow.webContents.openDevTools()
    })

    // Prevent closing, hide instead
    mainWindow.on('close', (event) => {
        if (!isQuitting) {
            event.preventDefault()
            mainWindow.hide()
        }
        return false
    })

    return mainWindow
}

app.whenReady().then(() => {
    const mainWindow = createWindow()

    // Create Tray
    const icon = nativeImage.createFromPath(join(__dirname, '../../resources/icon.png')) // Placeholder path
    tray = new Tray(icon)
    const contextMenu = Menu.buildFromTemplate([
        {
            label: 'Show SmartScribe', click: () => {
                mainWindow.show()
                mainWindow.focus()
            }
        },
        { type: 'separator' },
        {
            label: 'Quit', click: () => {
                isQuitting = true
                app.quit()
            }
        }
    ])
    tray.setToolTip('SmartScribe')
    tray.setContextMenu(contextMenu)

    // Toggle window on tray click
    tray.on('click', () => {
        if (mainWindow.isVisible()) {
            mainWindow.hide()
        } else {
            mainWindow.show()
            mainWindow.focus()
        }
    })

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow()
        else mainWindow.show()
    })
})

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit()
    }
})

import { ipcMain, systemPreferences } from 'electron'

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

ipcMain.handle('resize-window', (_event, width, height) => {
    const window = BrowserWindow.getFocusedWindow()
    if (window) {
        window.setSize(width, height, true)
        window.center()
    }
})

// Floating Waveform Window Management
let waveformWindow: BrowserWindow | null = null

const createWaveformWindow = () => {
    if (waveformWindow) return

    waveformWindow = new BrowserWindow({
        width: 100, // Slightly larger for debug visibility
        height: 100,
        frame: false,
        transparent: true,
        alwaysOnTop: true,
        skipTaskbar: true,
        resizable: true,
        hasShadow: false,
        focusable: true,
        webPreferences: {
            preload: join(__dirname, '../preload/index.js'),
            sandbox: false
        }
    })

    // Position detection will happen later, for now center bottom
    const { screen } = require('electron')
    const primaryDisplay = screen.getPrimaryDisplay()
    const { width, height } = primaryDisplay.workAreaSize
    waveformWindow.setPosition(Math.floor(width / 2 - 18), height - 80)

    // Load the waveform route
    if (process.env['ELECTRON_RENDERER_URL']) {
        waveformWindow.loadURL(`${process.env['ELECTRON_RENDERER_URL']}/#/waveform`)
    } else {
        waveformWindow.loadFile(join(__dirname, '../renderer/index.html'), { hash: 'waveform' })
    }

    waveformWindow.on('closed', () => {
        waveformWindow = null
    })
}

// IPC to open waveform
ipcMain.handle('open-waveform', () => {
    if (!waveformWindow) {
        createWaveformWindow()
    } else {
        waveformWindow.show()
    }
})

// Settings IPC
// Settings IPC
ipcMain.handle('get-settings', (_event, key) => {
    return (store as any).get(key)
})

ipcMain.handle('set-setting', (_event, key, value) => {
    (store as any).set(key, value)
})

ipcMain.handle('get-all-settings', () => {
    return (store as any).store
})
