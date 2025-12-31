import { ipcMain, clipboard, BrowserWindow } from 'electron'
import { exec } from 'child_process'

export const registerNativeHandlers = (): void => {
    // Active Window Detection
    ipcMain.handle('get-active-app', async () => {
        try {
            const activeWin = await import('active-win')
            const result = await activeWin.default()
            return {
                title: result?.title || '',
                owner: {
                    name: result?.owner?.name || '',
                    bundleId: (result?.owner as any)?.bundleId || '',
                    path: result?.owner?.path || ''
                }
            }
        } catch (error) {
            console.error('Failed to get active window:', error)
            return null
        }
    })

    // Check Input Focus
    ipcMain.handle('check-input-focus', async () => {
        const path = require('path')
        const fs = require('fs')

        // Use compiled binary
        let binaryPath: string;

        if (require('electron').app.isPackaged) {
            binaryPath = path.join(process.resourcesPath, 'bin', 'check-input')
        } else {
            binaryPath = path.join(__dirname, '../../resources/bin/check-input')
        }

        console.log('Main: checking input focus using binary at:', binaryPath);

        // Fallback to script if binary missing (legacy/dev fallback)
        if (!fs.existsSync(binaryPath)) {
            console.warn('Binary check-input not found at:', binaryPath, '- falling back to script')
            const scriptPath = require('electron').app.isPackaged
                ? path.join(process.resourcesPath, 'swift', 'check-input.swift')
                : path.join(__dirname, '../../src/main/swift/check-input.swift')

            return new Promise((resolve) => {
                exec(`swift "${scriptPath}"`, (error, stdout) => {
                    if (error) {
                        console.error('Check Input error (script fallback):', error)
                        resolve(false)
                        return
                    }
                    console.log('Main: script fallback check input result:', stdout.trim());
                    resolve(stdout.trim() === 'true')
                })
            })
        }

        return new Promise((resolve) => {
            exec(`"${binaryPath}"`, (error, stdout) => {
                if (error) {
                    console.error('Check Input error (binary):', error)
                    resolve(false)
                    return
                }
                const result = stdout.trim() === 'true'
                console.log('Main: binary check input result:', result, 'stdout:', stdout)
                resolve(result)
            })
        })
    })

    // Text Insertion (Clipboard + Cmd-V)
    ipcMain.handle('insert-text', async (_event, text: string) => {
        try {
            clipboard.writeText(text)

            if (process.platform === 'darwin') {
                const script = `tell application "System Events" to keystroke "v" using command down`
                exec(`osascript -e '${script}'`)
                return true
            } else {
                return false
            }
        } catch (error) {
            console.error('Failed to insert text:', error)
            return false
        }
    })

    // Window Resize
    ipcMain.handle('resize-window', (_event, width, height) => {
        const window = BrowserWindow.getFocusedWindow()
        if (window) {
            window.setSize(width, height, true)
            window.center()
        }
    })

    // Mouse Event Control (Click-through)
    ipcMain.on('set-ignore-mouse-events', (event, ignore, options) => {
        const window = BrowserWindow.fromWebContents(event.sender)
        if (window) {
            window.setIgnoreMouseEvents(ignore, options)
        }
    })

    // Debug Logging from Renderer
    ipcMain.on('log', (_event, message, data) => {
        if (data) {
            console.log(`[Renderer] ${message}`, data)
        } else {
            console.log(`[Renderer] ${message}`)
        }
    })
}
