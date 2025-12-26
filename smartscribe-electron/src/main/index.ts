import { app, BrowserWindow } from 'electron'
import { createMainWindow, setIsQuitting } from './windows/mainWindow'
import { createTray } from './tray/trayManager'
import { registerProtocol, setupSingleInstanceLock, setupMacOSProtocolHandler, getMainWindow } from './protocol/deepLinkHandler'
import { registerPermissionsHandlers } from './ipc/permissionsHandlers'
import { registerNativeHandlers } from './ipc/nativeHandlers'
import { registerSettingsHandlers, initializeGlobalShortcuts } from './ipc/settingsHandlers'
import { registerWindowHandlers } from './ipc/windowHandlers'

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
    const mainWindow = getMainWindow()
    if (mainWindow) {
        if (mainWindow.isMinimized()) mainWindow.restore()
        mainWindow.show()
        mainWindow.focus()
        mainWindow.webContents.send('deep-link', url)
    }
})

// App ready
app.whenReady().then(() => {
    const mainWindow = createMainWindow()

    // Create Tray
    const handleQuit = () => {
        setIsQuitting(true)
        app.quit()
    }
    createTray(mainWindow, handleQuit)

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
