import { app, BrowserWindow, Tray, Menu, nativeImage } from 'electron'
import { join, resolve } from 'path'
import Store from 'electron-store'

const store = new Store()

let tray: Tray | null = null

let isQuitting = false

// Protocol Registration
if (process.defaultApp) {
    if (process.argv.length >= 2) {
        app.setAsDefaultProtocolClient('voicescribe', process.execPath, [resolve(process.argv[1])])
    }
} else {
    app.setAsDefaultProtocolClient('voicescribe')
}

const gotTheLock = app.requestSingleInstanceLock()

if (!gotTheLock) {
    app.quit()
} else {
    app.on('second-instance', (_event, commandLine) => {
        // Someone tried to run a second instance, we should focus our window.
        const mainWindow = BrowserWindow.getAllWindows().find(w => !w.isDestroyed() && w !== waveformWindow)
        if (mainWindow) {
            if (mainWindow.isMinimized()) mainWindow.restore()
            mainWindow.show()
            mainWindow.focus()
        }

        // Protocol handler for Windows/Linux
        const url = commandLine.find((arg) => arg.startsWith('voicescribe://'))
        if (url && mainWindow) {
            mainWindow.webContents.send('deep-link', url)
        }
    })
}

// macOS Protocol Handler
app.on('open-url', (event, url) => {
    event.preventDefault()
    const mainWindow = BrowserWindow.getAllWindows().find(w => !w.isDestroyed() && w !== waveformWindow)
    if (mainWindow) {
        if (mainWindow.isMinimized()) mainWindow.restore()
        mainWindow.show()
        mainWindow.focus()
        mainWindow.webContents.send('deep-link', url)
    } else {
        // If window is not created yet, store it or wait? 
        // For now, we assume app is running or will be created soon.
        // Ideally we might want to store this URL and send it when window is ready.
        // But simplifying for now as app usually starts with a window.
    }
})

const createWindow = () => {
    const mainWindow = new BrowserWindow({
        width: 900, // Slightly larger starting size
        height: 670,
        minWidth: 800, // Match Swift L93
        minHeight: 600, // Match Swift L93
        show: false,
        frame: false,
        titleBarStyle: 'hidden', // Full control
        trafficLightPosition: { x: 20, y: 18 }, // Adjust traffic lights
        transparent: true, // Enable transparency for vibrancy
        vibrancy: 'under-window', // Match macOS window style
        visualEffectState: 'active', // Ensure vibrancy stays active
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

    // Load the remote URL for development or the local html file for production
    if (process.env['ELECTRON_RENDERER_URL']) {
        mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL'])
    } else {
        mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
    }

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

// --- Native Helper Features ---

// Active Window Detection
ipcMain.handle('get-active-app', async () => {
    try {
        // Dynamic import for ESM module
        const activeWin = await import('active-win');
        const result = await activeWin.default();
        return {
            title: result?.title || '',
            owner: {
                name: result?.owner?.name || '',
                bundleId: (result?.owner as any)?.bundleId || '',
                path: result?.owner?.path || ''
            }
        };
    } catch (error) {
        console.error('Failed to get active window:', error);
        return null;
    }
});

// Text Insertion (Clipboard + Cmd-V)
import { clipboard } from 'electron';
import { exec } from 'child_process';

ipcMain.handle('insert-text', async (_event, text: string) => {
    try {
        clipboard.writeText(text);

        // Use AppleScript to simulate Cmd+V
        if (process.platform === 'darwin') {
            const script = `tell application "System Events" to keystroke "v" using command down`;
            exec(`osascript -e '${script}'`);
            return true;
        } else {
            // Windows/Linux fallback (robotjs would be better here, but avoiding native deps if possible)
            // For now, we assume user manually pastes or we'll need another solution for Win/Linux
            return false;
        }
    } catch (error) {
        console.error('Failed to insert text:', error);
        return false;
    }
});

// Permissions Check (Combined)
ipcMain.handle('check-permissions', () => {
    const micStatus = process.platform === 'darwin'
        ? systemPreferences.getMediaAccessStatus('microphone')
        : 'granted';

    const accessibilityStatus = process.platform === 'darwin'
        ? systemPreferences.isTrustedAccessibilityClient(false)
        : true;

    return {
        microphone: micStatus,
        accessibility: accessibilityStatus
    };
});

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
        width: 600,
        height: 120,
        frame: false,
        transparent: true,
        alwaysOnTop: true,
        skipTaskbar: true,
        resizable: false,
        hasShadow: false,
        focusable: true, // Needs focus for interaction? Maybe false to not steal? User said "chip".
        type: 'panel', // macOS: floats above full screen apps
        webPreferences: {
            preload: join(__dirname, '../preload/index.js'),
            sandbox: false,
            backgroundThrottling: false
        }
    })

    // Initial Position
    updateWaveformPosition()

    // Screen Follow Logic (Poll cursor to allow moving to active screen)
    const positionInterval = setInterval(() => {
        if (!waveformWindow || waveformWindow.isDestroyed()) {
            clearInterval(positionInterval)
            return
        }
        updateWaveformPosition()
    }, 50)

    // Fullscreen Poll (Heavy, run less often)
    const fullscreenInterval = setInterval(() => {
        if (!waveformWindow || waveformWindow.isDestroyed()) {
            clearInterval(fullscreenInterval)
            return
        }
        checkFullscreenState()
    }, 1000)

    // Reactive Dock/Screen Logic
    const { screen } = require('electron')
    const handleDisplayChange = () => {
        if (waveformWindow && !waveformWindow.isDestroyed()) {
            updateWaveformPosition()
        }
    }
    screen.on('display-metrics-changed', handleDisplayChange)
    screen.on('work-area-changed', handleDisplayChange)

    // Load the waveform route
    if (process.env['ELECTRON_RENDERER_URL']) {
        waveformWindow.loadURL(`${process.env['ELECTRON_RENDERER_URL']}/#/waveform`)
    } else {
        waveformWindow.loadFile(join(__dirname, '../renderer/index.html'), { hash: 'waveform' })
    }

    waveformWindow.on('closed', () => {
        waveformWindow = null
        clearInterval(positionInterval)
        clearInterval(fullscreenInterval)
        // Clean up listeners
        screen.removeListener('display-metrics-changed', handleDisplayChange)
        screen.removeListener('work-area-changed', handleDisplayChange)
    })
}

// Fullscreen Detection State
let isFullscreen = false

const checkFullscreenState = async () => {
    try {
        const { screen } = require('electron')
        const activeWin = await import('active-win')
        const result = await activeWin.default()

        if (result && result.bounds) {
            const cursorPoint = screen.getCursorScreenPoint()
            const display = screen.getDisplayNearestPoint(cursorPoint)

            // Check if active window covers the entire display
            const isFull = (
                result.bounds.x === display.bounds.x &&
                result.bounds.y === display.bounds.y &&
                result.bounds.width === display.bounds.width &&
                result.bounds.height === display.bounds.height
            )
            isFullscreen = isFull
        }
    } catch (e) {
        // Fallback or ignore
        isFullscreen = false
    }
}

const updateWaveformPosition = () => {
    if (!waveformWindow || waveformWindow.isDestroyed()) return
    const { screen } = require('electron')

    // Get display regarding cursor (restore following behavior)
    const cursorPoint = screen.getCursorScreenPoint()
    const display = screen.getDisplayNearestPoint(cursorPoint)

    // Calculate center bottom of the display's work area
    const { x, y, width, height } = display.workArea
    const winBounds = waveformWindow.getBounds()

    // Default: 8px above bottom of workArea (excludes dock)
    let targetX = Math.floor(x + (width / 2) - (winBounds.width / 2))
    let targetY = Math.floor(y + height - winBounds.height - 8)

    // Override if Fullscreen (Dock is hidden by MacOS logic in fullscreen spaces)
    if (isFullscreen) {
        // Position at absolute bottom of screen
        // display.bounds.y + display.bounds.height is the absolute bottom
        const absoluteBottom = display.bounds.y + display.bounds.height
        targetY = Math.floor(absoluteBottom - winBounds.height - 8)
    }

    // Apply strictly if there's any deviation (sticky behavior)
    if (winBounds.x !== targetX || winBounds.y !== targetY) {
        waveformWindow.setPosition(targetX, targetY)
    }
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

// Mouse Event Control (Click-through)
ipcMain.on('set-ignore-mouse-events', (event, ignore, options) => {
    const window = BrowserWindow.fromWebContents(event.sender)
    if (window) {
        window.setIgnoreMouseEvents(ignore, options)
    }
})
