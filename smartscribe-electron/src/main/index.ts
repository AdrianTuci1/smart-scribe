import { app, BrowserWindow, ipcMain, clipboard } from 'electron'
import { createMainWindow, setIsQuitting } from './windows/mainWindow'
import { createTray } from './tray/trayManager'
import { registerProtocol, setupSingleInstanceLock, setupMacOSProtocolHandler, getMainWindow } from './protocol/deepLinkHandler'
import { registerPermissionsHandlers } from './ipc/permissionsHandlers'
import { registerNativeHandlers } from './ipc/nativeHandlers'
import { registerSettingsHandlers, initializeGlobalShortcuts } from './ipc/settingsHandlers'
import { registerWindowHandlers } from './ipc/windowHandlers'
import { KeyMonitorService } from './services/KeyMonitorService'

// Register protocol for deep linking
registerProtocol()

// Setup single instance lock
const hasLock = setupSingleInstanceLock((url) => {
    const mainWindow = getMainWindow()
    if (mainWindow) {
        if (mainWindow.isMinimized()) mainWindow.restore()
        mainWindow.show()
        mainWindow.focus()

        if (url) {
            mainWindow.webContents.send('deep-link', url)
        }
    }
})

if (!hasLock) {
    // App will quit if we didn't get the lock
    // setupSingleInstanceLock already calls app.quit()
}

// macOS Protocol Handler
setupMacOSProtocolHandler((url) => {
    console.log('Main: setupMacOSProtocolHandler triggered with:', url)
    const mainWindow = getMainWindow()
    if (mainWindow) {
        console.log('Main: mainWindow found, ID:', mainWindow.id)
        if (mainWindow.isMinimized()) mainWindow.restore()
        mainWindow.show()
        mainWindow.focus()

        // Slight delay to ensure renderer is ready after focus
        setTimeout(() => {
            mainWindow.webContents.send('deep-link', url)
            console.log('Main: deep-link IPC sent to mainWindow (delayed)')
        }, 500)
    } else {
        console.error('Main: No mainWindow found to send deep-link!')
    }
})

// Clipboard IPC
ipcMain.on('clipboard-write', (_event, text) => {
    if (text) {
        clipboard.writeText(text);
        console.log('Main: Copied text to clipboard:', text.substring(0, 50) + '...');
    }
});

// App ready
app.whenReady().then(() => {
    const mainWindow = createMainWindow()

    // Create Tray
    const handleQuit = () => {
        setIsQuitting(true)
        app.quit()
    }
    createTray(mainWindow, handleQuit)

    // Start Key Monitor
    new KeyMonitorService();

    // Set Dock Icon (macOS)
    if (process.platform === 'darwin') {
        const path = require('path');
        const logoPath = app.isPackaged
            ? path.join(process.resourcesPath, 'logo.png')
            : path.join(__dirname, '../../resources/logo.png');
        app.dock?.setIcon(logoPath);
    }

    // Register all IPC handlers
    registerPermissionsHandlers()
    registerNativeHandlers()
    registerSettingsHandlers()
    registerWindowHandlers()

    // Activate handler for macOS
    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createMainWindow()
        } else {
            mainWindow.show()
        }
    })
})

// Initialize global shortcuts after app is ready
app.on('ready', () => {
    initializeGlobalShortcuts()
})

// Window all closed handler
app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit()
    }
})
