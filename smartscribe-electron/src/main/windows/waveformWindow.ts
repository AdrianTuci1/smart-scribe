import { BrowserWindow, screen } from 'electron'
import { join } from 'path'

let waveformWindow: BrowserWindow | null = null
let isFullscreen = false

const checkFullscreenState = async () => {
    try {
        const cursorPoint = screen.getCursorScreenPoint()
        const display = screen.getDisplayNearestPoint(cursorPoint)

        // When any app is in fullscreen on macOS, the menu bar is hidden
        // This means workArea.y will be 0 (no menu bar offset)
        // In normal mode, workArea.y > 0 (menu bar takes space at top)
        const isMenuBarHidden = display.workArea.y === 0

        console.log('Fullscreen Check:', {
            workArea: display.workArea,
            bounds: display.bounds,
            isMenuBarHidden,
            finalFullscreenState: isMenuBarHidden
        })

        if (isFullscreen !== isMenuBarHidden) {
            console.log(`Fullscreen state changed: ${isFullscreen} -> ${isMenuBarHidden}`)
            isFullscreen = isMenuBarHidden
            if (waveformWindow && !waveformWindow.isDestroyed()) {
                waveformWindow.webContents.send('fullscreen-state-changed', isFullscreen)
            }
            // Immediately update position when fullscreen state changes
            updateWaveformPosition()
        }
    } catch (e) {
        console.error('Error checking fullscreen state:', e)
        if (isFullscreen !== false) {
            isFullscreen = false
            if (waveformWindow && !waveformWindow.isDestroyed()) {
                waveformWindow.webContents.send('fullscreen-state-changed', isFullscreen)
            }
        }
    }
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
        console.log('Fullscreen mode: positioning at absolute bottom', { targetY, absoluteBottom })
    }

    console.log('Position update:', {
        isFullscreen,
        workArea: display.workArea,
        displayBounds: display.bounds,
        currentPos: { x: winBounds.x, y: winBounds.y },
        targetPos: { x: targetX, y: targetY }
    })

    if (winBounds.x !== targetX || winBounds.y !== targetY) {
        waveformWindow.setPosition(targetX, targetY)
    }
}

export const createWaveformWindow = (): void => {
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
        focusable: true,
        type: 'panel',
        webPreferences: {
            preload: join(__dirname, '../preload/index.js'),
            sandbox: false,
            backgroundThrottling: false
        }
    })

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
            updateWaveformPosition()
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
        clearInterval(positionInterval)
        clearInterval(fullscreenInterval)
        screen.removeListener('display-metrics-changed', handleDisplayChange)
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
