import { ipcMain, clipboard, BrowserWindow } from 'electron'
import { exec } from 'child_process'
import * as path from 'path'
import * as fs from 'fs'

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
        // Use compiled binary
        let binaryPath: string;

        // Robust path resolution logic
        const possiblePaths = [
            path.join(process.resourcesPath, 'bin', 'check-input'),
            path.join(process.resourcesPath, 'check-input'),
            path.join(__dirname, '../../resources/bin/check-input'),
            path.join(__dirname, '../../../resources/bin/check-input'),
            // Dev environment fallback (from main/ipc/...)
            path.join(__dirname, '../../../../resources/bin/check-input'),
            path.join(process.cwd(), 'resources/bin/check-input')
        ];

        binaryPath = possiblePaths.find(p => fs.existsSync(p)) || '';

        console.log('Main: checking input focus. Binary path found:', binaryPath || 'NONE');

        if (!binaryPath) {
            console.warn('Binary check-input not found. Trying script fallback.');
            // Fallback to script
            const scriptPossiblePaths = [
                path.join(process.resourcesPath, 'swift', 'check-input.swift'),
                path.join(__dirname, '../../resources/swift/check-input.swift'),
                path.join(__dirname, '../../src/main/swift/check-input.swift'),
                path.join(process.cwd(), 'resources/swift/check-input.swift')
            ];
            const scriptPath = scriptPossiblePaths.find(p => fs.existsSync(p));

            if (!scriptPath) {
                console.error('Check Input error: No binary or script found');
                return false;
            }

            return new Promise((resolve) => {
                const timeout = setTimeout(() => {
                    console.log('Main: check-input-focus script timed out');
                    resolve(false);
                }, 1000);

                exec(`swift "${scriptPath}"`, (error, stdout) => {
                    clearTimeout(timeout);
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
            const timeout = setTimeout(() => {
                console.log('Main: check-input-focus binary timed out');
                resolve(false);
            }, 1000);

            exec(`"${binaryPath}"`, (error, stdout) => {
                clearTimeout(timeout);
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
            console.log('Main: insert-text called with text length:', text.length);
            clipboard.writeText(text);
            console.log('Main: Text written to clipboard');

            if (process.platform === 'darwin') {
                console.log('Main: Simulating Cmd+V via AppleScript');
                const script = `tell application "System Events" to keystroke "v" using command down`

                return new Promise((resolve) => {
                    exec(`osascript -e '${script}'`, (error) => {
                        if (error) {
                            console.error('Main: Failed to execute paste script:', error);
                            // Even if paste fails, clipboard has it.
                            resolve(false);
                        } else {
                            console.log('Main: Paste script executed successfully');
                            resolve(true);
                        }
                    })
                });
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

    // Open External URL
    ipcMain.handle('open-external', async (_event, url: string) => {
        const { shell } = await import('electron');
        await shell.openExternal(url);
    });

    // Mute Music (Pause Players)
    ipcMain.on('mute-music', () => {
        if (process.platform === 'darwin') {
            console.log('Main: mute-music handler triggered. Pausing media players...');
            const script = `
                tell application "System Events"
                    set runningApps to name of every application process
                end tell
                
                if "Music" is in runningApps then
                    try
                        tell application "Music" to pause
                        log "Paused Music"
                    on error
                        log "Failed to pause Music"
                    end try
                end if
                
                if "Spotify" is in runningApps then
                    try
                        tell application "Spotify" to pause
                        log "Paused Spotify"
                    on error
                        log "Failed to pause Spotify"
                    end try
                end if
            `;

            exec(`osascript -e '${script}'`, (error, stdout) => {
                if (error) {
                    console.error('Failed to execute mute-music AppleScript:', error);
                } else {
                    console.log('Mute-music script output:', stdout.trim());
                }
            });
        }
    });
}
