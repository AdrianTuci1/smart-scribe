import { spawn, ChildProcess } from 'child_process';
import { app, BrowserWindow, webContents } from 'electron';
import path from 'path';
import { createInterface } from 'readline';

export class KeyMonitorService {
    private process: ChildProcess | null = null;
    private isRunning = false;

    constructor() {
        this.start();
        app.on('before-quit', () => this.stop());
    }

    public start() {
        if (this.isRunning) return;

        const executablePath = app.isPackaged
            ? path.join(process.resourcesPath, 'bin', 'key-monitor')
            : path.join(__dirname, '../../resources/bin/key-monitor');

        console.log('[KeyMonitor] Starting process:', executablePath);

        try {
            this.process = spawn(executablePath);
            this.isRunning = true;

            if (this.process.stdout) {
                const rl = createInterface({
                    input: this.process.stdout,
                    crlfDelay: Infinity
                });

                rl.on('line', (line) => {
                    try {

                        const event = JSON.parse(line);
                        // Broadcast to all renderers
                        const windows = BrowserWindow.getAllWindows();
                        windows.forEach(win => {
                            if (!win.isDestroyed()) {
                                win.webContents.send('global-key-event', event);
                            }
                        });
                    } catch (e) {
                        console.error('[KeyMonitor] Parse error:', e, line);
                    }
                });
            }

            if (this.process.stderr) {
                this.process.stderr.on('data', (data) => {
                    console.error('[KeyMonitor] Error:', data.toString());
                });
            }

            this.process.on('close', (code) => {
                console.log(`[KeyMonitor] Process exited with code ${code}`);
                this.isRunning = false;
            });

        } catch (error) {
            console.error('[KeyMonitor] Failed to spawn:', error);
        }
    }

    public stop() {
        if (this.process) {
            console.log('[KeyMonitor] Stopping process');
            this.process.kill();
            this.process = null;
            this.isRunning = false;
        }
    }
}
