import SwiftUI
import AppKit

/// A view that provides access to the underlying NSWindow for customization
struct WindowAccessor: NSViewRepresentable {
    var onWindowAvailable: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = WindowAccessorView()
        view.onWindowAvailable = onWindowAvailable
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Re-apply configuration on updates
        if let view = nsView as? WindowAccessorView, let window = view.window {
            view.onWindowAvailable?(window)
        }
    }
}

/// Custom NSView that detects when it's added to a window and observes layout changes
class WindowAccessorView: NSView {
    var onWindowAvailable: ((NSWindow) -> Void)?
    private var frameObserver: NSObjectProtocol?
    private var resizeObserver: NSObjectProtocol?
    private var fullscreenObserver: NSObjectProtocol?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        // Clean up previous observers
        removeObservers()
        
        if let window = window {
            // Apply immediately
            applyWindowConfiguration(window)
            
            // Also apply after a short delay to ensure window is fully set up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.applyWindowConfiguration(window)
            }
            
            // Observe frame changes to reapply traffic light positions
            frameObserver = NotificationCenter.default.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: window.contentView?.superview,
                queue: .main
            ) { [weak self, weak window] _ in
                guard let window = window else { return }
                self?.applyWindowConfiguration(window)
            }
            
            // Observe window resize
            resizeObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { [weak self, weak window] _ in
                guard let window = window else { return }
                // Delay slightly to let macOS finish its layout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.applyWindowConfiguration(window)
                }
            }
            
            // Observe fullscreen changes
            fullscreenObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didExitFullScreenNotification,
                object: window,
                queue: .main
            ) { [weak self, weak window] _ in
                guard let window = window else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.applyWindowConfiguration(window)
            }
        }
        }
    }
    
    private func applyWindowConfiguration(_ window: NSWindow) {
        onWindowAvailable?(window)
    }
    
    private func removeObservers() {
        if let observer = frameObserver {
            NotificationCenter.default.removeObserver(observer)
            frameObserver = nil
        }
        if let observer = resizeObserver {
            NotificationCenter.default.removeObserver(observer)
            resizeObserver = nil
        }
        if let observer = fullscreenObserver {
            NotificationCenter.default.removeObserver(observer)
            fullscreenObserver = nil
        }
    }
    
    deinit {
        removeObservers()
    }
}

/// Extension to customize window appearance including traffic light position
extension NSWindow {
    /// Adjusts the position of traffic light buttons (close, minimize, zoom)
    /// xOffset: horizontal offset from left edge (default ~8)
    /// yOffset: vertical offset from top edge (default ~4)
    func setTrafficLightsOffset(x xOffset: CGFloat = 8, y yOffset: CGFloat = 4) {
        guard let closeButton = standardWindowButton(.closeButton),
              let minimizeButton = standardWindowButton(.miniaturizeButton),
              let zoomButton = standardWindowButton(.zoomButton) else {
            return
        }
        
        let buttons = [closeButton, minimizeButton, zoomButton]
        let buttonSpacing: CGFloat = 20 // Standard spacing between traffic lights
        
        // Move the controls slightly lower for better alignment
        let adjustedYOffset = yOffset + 10
        
        for (index, button) in buttons.enumerated() {
            guard let superview = button.superview else { continue }
            
            // Calculate new position
            let newX = xOffset + CGFloat(index) * buttonSpacing
            let newY = superview.bounds.height - button.bounds.height - adjustedYOffset
            
            button.setFrameOrigin(CGPoint(x: newX, y: newY))
        }
    }
    
    /// Adjusts only the vertical position (convenience method)
    func setTrafficLightsVerticalOffset(_ yOffset: CGFloat) {
        setTrafficLightsOffset(x: 8, y: yOffset)
    }
}
