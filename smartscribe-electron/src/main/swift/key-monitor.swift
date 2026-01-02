import AppKit
import ApplicationServices
import Foundation

// Unbuffered IO
setbuf(stdout, nil)

struct KeyEvent: Codable {
    let type: String // "keydown", "keyup", "flagsChanged"
    let keyCode: Int16
    let chars: String
    let modifiers: [String]
    let timestamp: Double
}

func getModifiers(flags: CGEventFlags) -> [String] {
    var mods: [String] = []
    if flags.contains(.maskAlphaShift) { mods.append("CapsLock") }
    if flags.contains(.maskShift) { mods.append("Shift") }
    if flags.contains(.maskControl) { mods.append("Control") }
    if flags.contains(.maskAlternate) { mods.append("Alt") }
    if flags.contains(.maskCommand) { mods.append("Cmd") }
    if flags.contains(.maskSecondaryFn) { mods.append("Fn") }
    return mods
}

func output(event: KeyEvent) {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(event), let str = String(data: data, encoding: .utf8) {
        print(str)
    }
}

var eventTap: CFMachPort?

// Event Tap Callback
let callback: CGEventTapCallBack = { (proxy, type, event, refcon) in
    
    // Auto-enable if disabled
    if type == .tapDisabledByTimeout {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false) // Reset
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }
    
    // We only care about key events
    var eventType = ""
    switch type {
    case .keyDown: eventType = "keydown"
    case .keyUp: eventType = "keyup"
    case .flagsChanged: eventType = "flagsChanged"
    default: return Unmanaged.passUnretained(event)
    }
    
    let keyCode = Int16(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = event.flags
    let modifiers = getModifiers(flags: flags)
    
    // Get characters (only for key events, not flagsChanged)
    var chars = ""
    if type == .keyDown || type == .keyUp {
        if let nsEvent = NSEvent(cgEvent: event) {
            // Safety check although type check should suffice
            if nsEvent.type == .keyDown || nsEvent.type == .keyUp {
                 if let c = nsEvent.charactersIgnoringModifiers {
                    chars = c.uppercased()
                 }
            }
        }
    }
    
    // Fallback for special keys if chars is empty or for specific codes
    if chars.isEmpty {
         // Manual mapping for some keys if NSEvent doesn't help or if we are in a pure CG context
         // But NSEvent(cgEvent:) usually works.
    }
    
    // Specific overrides for readability
    if keyCode == 49 { chars = "Space" }
    if keyCode == 36 { chars = "Enter" }
    if keyCode == 53 { chars = "Esc" }
    if keyCode == 51 { chars = "Backspace" }
    if keyCode == 48 { chars = "Tab" }
    
    let keyEvent = KeyEvent(
        type: eventType,
        keyCode: keyCode,
        chars: chars,
        modifiers: modifiers,
        timestamp: Date().timeIntervalSince1970
    )
    
    // ARROW KEY FILTERING:
    // Don't send arrow keys to the app (they should not interact with the waveform window)
    // Arrow Left: 123, Arrow Right: 124, Arrow Down: 125, Arrow Up: 126
    let isArrowKey = [123, 124, 125, 126].contains(Int(keyCode))
    
    if !isArrowKey {
        output(event: keyEvent)
    }
    
    // BLOCKING LOGIC:
    // If Fn key (63), swallow the event to prevent system Emoji picker.
    // Note: We still outputted the event above so our app sees it.
    if keyCode == 63 {
        return nil
    }
    
    return Unmanaged.passUnretained(event)
}

// Create Event Tap
let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

// Assign to global variable
// Note: We used guard let logic before, but now we assign to var.
let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap, // Active blocking tap
    eventsOfInterest: CGEventMask(eventMask),
    callback: callback,
    userInfo: nil
)

if tap == nil {
    print("{\"error\": \"failed to create event tap\"}")
    exit(1)
}

eventTap = tap

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap!, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap!, enable: true)

// Keep running
CFRunLoopRun()
