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
}
