import Cocoa
import Carbon

class GlobalHotkeyMonitor {
    static let shared = GlobalHotkeyMonitor()
    
    private var eventMonitor: Any?
    
    private init() {}
    
    func startMonitoring(handler: @escaping () -> Void) {
        // Check for Accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility permissions not granted. Global hotkey will not work.")
            // In a real app, you might want to show an alert to the user here
            // asking them to enable it in System Settings.
            return
        }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // Check for Fn key (keyCode 63)
            if event.keyCode == 63 {
                handler()
            }
        }
    }
    
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
