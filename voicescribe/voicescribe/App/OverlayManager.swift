import Cocoa
import SwiftUI

import Combine

class OverlayManager: ObservableObject {
    // objectWillChange is synthesized automatically for @Published properties, 
    // or manually if needed, but usually we don't need to declare it explicitly unless we override it.
    // However, the error said "Cannot find type 'ObservableObjectPublisher' in scope", which means Combine was missing.
    // But also "Class 'OverlayManager' has no initializers".
    
    var overlayWindow: NSPanel?
    
    public init() {}
    
    func showOverlay(isRecording: Bool) {
        if overlayWindow == nil {
            createOverlay()
        }
        
        if isRecording {
            overlayWindow?.orderFront(nil)
        } else {
            overlayWindow?.orderOut(nil)
        }
    }
    
    private func createOverlay() {
        let overlay = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 60), // Increased width/height for new design
            styleMask: [.nonactivatingPanel, .borderless, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        overlay.level = .floating
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlay.backgroundColor = .clear
        overlay.isOpaque = false
        overlay.hasShadow = false // View has its own shadow now
        
        // Center horizontally, near bottom
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 100
            let y = screenRect.minY + 100
            overlay.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        let contentView = WaveformView(isRecording: true) // Always animating in overlay when shown
        overlay.contentViewController = NSHostingController(rootView: contentView)
        
        self.overlayWindow = overlay
    }
}
