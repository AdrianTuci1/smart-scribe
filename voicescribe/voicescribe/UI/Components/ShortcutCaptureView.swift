import SwiftUI
import Carbon

struct ShortcutCaptureView: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void
    
    @State private var eventMonitor: Any?
    @State private var currentKeystrokes: String = "Press keys..."
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Recording Shortcut")
                .font(.headline)
            
            Text(currentKeystrokes)
                .font(.system(size: 24, weight: .bold))
                .padding()
                .frame(width: 300, height: 80)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
            
            Text("Press Esc to cancel")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel") {
                    cleanup()
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    if currentKeystrokes != "Press keys..." {
                        onSave(currentKeystrokes)
                    }
                    cleanup()
                    isPresented = false
                }
                .disabled(currentKeystrokes == "Press keys..." || currentKeystrokes.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 250)
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func startMonitoring() {
        // Use a local monitor to intercept events while this window is focused
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            // Handle Escape to cancel
            if event.keyCode == 53 { // 53 is Esc
                cleanup()
                isPresented = false
                return nil
            }
            
            // Reconstruct the shortcut string
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyCode = event.keyCode
            
            var keys: [String] = []
            
            // Add modifiers
            if flags.contains(.command) { keys.append("Cmd") }
            if flags.contains(.control) { keys.append("Ctrl") }
            if flags.contains(.option) { keys.append("Opt") }
            if flags.contains(.shift) { keys.append("Shift") }
            if flags.contains(.function) { keys.append("Fn") }
            
            // If it's just a modifier key press (flagsChanged), we update the display
            // If it's a keyDown, we append the character
            
            if event.type == .keyDown {
                // Handle special keys manually or use characters
                // 63 is Fn key on some keyboards, but usually Fn is just a flag
                // If the user wants to set "Fn" as a hotkey, they typically mean "Double press Fn" or similar, 
                // but for a single key combination, Fn is a modifier.
                // However, "Globe" key or Fn key as distinct key is code 63.
                
                if keyCode == 63 {
                     if !keys.contains("Fn") { keys.append("Fn") }
                } else {
                    // Map common keycodes or use charactersIgnoringModifiers
                    if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
                        // Handle special labels for non-printable keys
                        let label = getKeyLabel(keyCode: keyCode, chars: chars)
                        keys.append(label)
                    }
                }
            } else if event.type == .flagsChanged {
                // If it's just flags, we show them. 
                // Wait for a non-modifier key or just let them save a modifier-only combo?
                // Usually shortcut is Modifier+Key. 
                // But some users map "Fn" single press.
                if event.keyCode == 63 { // Fn pressed alone
                     if !keys.contains("Fn") { keys.append("Fn") }
                }
            }
            
            self.currentKeystrokes = keys.joined(separator: " + ")
            
            // Consume the event so it doesn't propagate
            return nil
        }
    }
    
    private func getKeyLabel(keyCode: UInt16, chars: String) -> String {
        switch keyCode {
        case 53: return "Esc"
        case 49: return "Space"
        case 36: return "Enter"
        case 48: return "Tab"
        case 51: return "Delete"
        case 123: return "Left"
        case 124: return "Right"
        case 125: return "Down"
        case 126: return "Up"
        // F-keys
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default: return chars
        }
    }
    
    private func cleanup() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
