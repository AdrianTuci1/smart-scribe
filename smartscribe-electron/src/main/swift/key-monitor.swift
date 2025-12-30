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

// Event Tap Callback
let callback: CGEventTapCallBack = { (proxy, type, event, refcon) in
    
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
    
    output(event: keyEvent)
    
    return Unmanaged.passUnretained(event)
}

// Create Event Tap
let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: callback,
    userInfo: nil
) else {
    print("{\"error\": \"failed to create event tap\"}")
    exit(1)
}

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

// Keep running
CFRunLoopRun()
