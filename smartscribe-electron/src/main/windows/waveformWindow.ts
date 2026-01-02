import { BrowserWindow, screen } from 'electron'
import { join } from 'path'
import { execFile } from 'child_process'
import path from 'path'
import fs from 'fs'

let waveformWindow: BrowserWindow | null = null
let isFullscreen = false
// Worker removed
let currentActiveApp: string = 'Unknown'

const getBinaryPath = () => {
    const binName = 'active-window'
    // 1. Try dev path (cwd/resources/bin)
    const devPath = path.resolve(process.cwd(), 'resources/bin', binName)
    if (fs.existsSync(devPath)) return devPath

    // 2. Try production resources path
    // In prod, resource path handling might vary, but this covers dev.
    return devPath
}

const binaryPath = getBinaryPath()

const checkActiveWindow = () => {
    execFile(binaryPath, (error, stdout, stderr) => {
        if (error) {
            // console.error('ActiveWindow error:', stderr || error.message)
            return
        }
        try {
            const win = JSON.parse(stdout)

            // Log debug message from Swift helper
            if (win.debug) console.log(win.debug)

            // Map Swift helper fields: appName, windowTitle
            currentActiveApp = win ? `${win.appName} (${win.windowTitle})` : 'Unknown'

            // Swift helper provides accurate fullscreen status
            const newIsFullscreen = win ? win.fullscreen : false

            if (isFullscreen !== newIsFullscreen) {
                console.log(`Fullscreen state changed: ${isFullscreen} -> ${newIsFullscreen}`)
                isFullscreen = newIsFullscreen
                if (waveformWindow && !waveformWindow.isDestroyed()) {
                    // Update workspace visibility:
                    // - True: allows floating over fullscreen apps
                    // - False: restricts to current desktop (fixes movement between monitors)
                    waveformWindow.setVisibleOnAllWorkspaces(isFullscreen, { visibleOnFullScreen: isFullscreen })

                    // - Low level: floating (standard always on top)
                    // - High level: screen-saver (above fullscreen apps)
                    const level = isFullscreen ? 'screen-saver' : 'floating'
                    waveformWindow.setAlwaysOnTop(true, level)

                    waveformWindow.webContents.send('fullscreen-state-changed', isFullscreen)
                }
                updateWaveformPosition()
            }
        } catch (e) {
            console.error('Failed to parse active-window output', e)
        }
    })
}

const checkFullscreenState = async () => {
    // Request update directly
    checkActiveWindow()
}

const updateWaveformPosition = () => {
    if (!waveformWindow || waveformWindow.isDestroyed()) return

    const cursorPoint = screen.getCursorScreenPoint()
    const display = screen.getDisplayNearestPoint(cursorPoint)

    const { x, y, width, height } = display.workArea
    const winBounds = waveformWindow.getBounds()

    let targetX = Math.floor(x + (width / 2) - (winBounds.width / 2))
    let targetY = Math.floor(y + height - winBounds.height - 8)

    if (isFullscreen) {
        const absoluteBottom = display.bounds.y + display.bounds.height
        targetY = Math.floor(absoluteBottom - winBounds.height - 8)
    }

    if (winBounds.x !== targetX || winBounds.y !== targetY) {
        waveformWindow.setPosition(targetX, targetY)
    }
}

export const createWaveformWindow = (): void => {
    if (waveformWindow) return

    // Worker start removed

    waveformWindow = new BrowserWindow({
        width: 600,
        height: 400, // Increased height to fit warning toast
        frame: false,
        transparent: true,
        alwaysOnTop: true,
        skipTaskbar: true,
        resizable: false,
        hasShadow: false,
        focusable: false,
        title: 'Recording orb',
        // type: 'panel', // Causes NSWindow styleMask warning on some macOS versions
        webPreferences: {
            preload: join(__dirname, '../preload/index.js'),
            sandbox: false,
            backgroundThrottling: false
        }
    })

    waveformWindow.setIgnoreMouseEvents(true, { forward: true })

    updateWaveformPosition()

    const positionInterval = setInterval(() => {
        if (!waveformWindow || waveformWindow.isDestroyed()) {
            clearInterval(positionInterval)
            return
        }
        updateWaveformPosition()
    }, 50)

    const fullscreenInterval = setInterval(() => {
        if (!waveformWindow || waveformWindow.isDestroyed()) {
            clearInterval(fullscreenInterval)
            return
        }
        checkFullscreenState()
    }, 1000)

    const handleDisplayChange = () => {
        if (waveformWindow && !waveformWindow.isDestroyed()) {
            // Check fullscreen state immediately when display metrics change (like Space transition)
            checkFullscreenState()
        }
    }


    screen.on('display-metrics-changed', handleDisplayChange)


    if (process.env['ELECTRON_RENDERER_URL']) {
        waveformWindow.loadURL(`${process.env['ELECTRON_RENDERER_URL']}/#/waveform`)
    } else {
        waveformWindow.loadFile(join(__dirname, '../renderer/index.html'), { hash: 'waveform' })
    }

    waveformWindow.on('closed', () => {
        waveformWindow = null
        // Worker cleanup removed
        clearInterval(positionInterval)
        clearInterval(fullscreenInterval)
        screen.removeListener('display-metrics-changed', handleDisplayChange)
    })

    waveformWindow.on('enter-full-screen', () => {
        // System started moving to a new Space
        console.log('Window entered full-screen state change start')

        // Wait for the animation to finish (approx 500ms on macOS)
        setTimeout(() => {
            // Window is now stable on the new Space
            console.log("Window is now stable on the new Space.");

            // Check state again
            const isNowFull = waveformWindow?.isFullScreen();
            console.log("Confirmation status:", isNowFull);

            // Trigger custom state check
            checkFullscreenState()
        }, 600)
    })
}

export const showWaveformWindow = (): void => {
    if (!waveformWindow) {
        createWaveformWindow()
    } else {
        waveformWindow.show()
    }
}

export const getWaveformWindow = (): BrowserWindow | null => {
    return waveformWindow
}
