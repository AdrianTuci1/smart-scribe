import { Tray, Menu, nativeImage, BrowserWindow, app } from 'electron'
import { join } from 'path'
import Store from 'electron-store'

const store = new Store()
let tray: Tray | null = null

export const createTray = (mainWindow: BrowserWindow, onQuit: () => void): Tray => {
    const icon = nativeImage.createFromPath(join(__dirname, '../../resources/tray.png'))
    tray = new Tray(icon)

    const updateTrayMenu = () => {
        const lastTranscript = (store as any).get('lastTranscript')
        const contextMenu = Menu.buildFromTemplate([
            {
                label: 'Home',
                click: () => {
                    mainWindow.show()
                    mainWindow.focus()
                }
            },
            {
                label: 'Check for updates...',
                click: () => {
                    const { shell } = require('electron')
                    shell.openExternal('https://smartscribe.app/updates')
                }
            },
            {
                label: 'Paste last transcript',
                accelerator: 'Ctrl+Command+V',
                enabled: !!lastTranscript,
                click: () => {
                    if (lastTranscript) {
                        const { clipboard } = require('electron')
                        const { exec } = require('child_process')
                        clipboard.writeText(lastTranscript)
                        if (process.platform === 'darwin') {
                            const script = `tell application "System Events" to keystroke "v" using command down`
                            exec(`osascript -e '${script}'`)
                        }
                    }
                }
            },
            { type: 'separator' },
            { label: 'Shortcuts', enabled: false },
            {
                label: 'Microphone',
                submenu: [
                    { label: 'Auto-detect (System Default)', type: 'radio', checked: true },
                    { label: 'Built-in Microphone', type: 'radio', checked: false }
                ]
            },
            {
                label: 'Languages',
                submenu: [
                    { label: 'English', type: 'radio', checked: true },
                    { label: 'Romanian', type: 'radio', checked: false }
                ]
            },
            { type: 'separator' },
            {
                label: 'Help Center',
                click: () => {
                    require('electron').shell.openExternal('https://help.smartscribe.ai')
                }
            },
            {
                label: 'Talk to support',
                accelerator: 'Command+/',
                click: () => {
                    require('electron').shell.openExternal('https://smartscribe.ai/support')
                }
            },
            {
                label: 'General feedback',
                click: () => {
                    require('electron').shell.openExternal('mailto:feedback@smartscribe.ai')
                }
            },
            { type: 'separator' },
            {
                label: 'Quit SmartScribe',
                accelerator: 'Command+Q',
                click: onQuit
            }
        ])
        tray?.setContextMenu(contextMenu)
    }

    updateTrayMenu()
    tray.setToolTip('SmartScribe')

    tray.on('click', () => {
        if (mainWindow.isVisible()) {
            mainWindow.hide()
        } else {
            mainWindow.show()
            mainWindow.focus()
        }
    })

    return tray
}

export const updateTrayMenu = (): void => {
    // This can be called externally to refresh the menu
    if (tray) {
        // Re-create the menu with updated data
        // For now, we'll just trigger a rebuild
    }
}

export const getTray = (): Tray | null => {
    return tray
}
