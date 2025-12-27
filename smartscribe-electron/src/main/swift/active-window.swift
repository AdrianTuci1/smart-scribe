import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct Bounds: Codable {
    let x: Double
    let y: Double
    let w: Double
    let h: Double
}

struct Output: Codable {
    let bundleId: String?
    let appName: String?
    let windowTitle: String?
    let fullscreen: Bool
    let bounds: Bounds
    let debug: String
}

func output(json: Output) {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(json), let str = String(data: data, encoding: .utf8) {
        print(str)
    } else {
        print("{}")
    }
    exit(0)
}

func outputError(_ msg: String) {
    // Fallback JSON with error in debug
    print("{\"debug\": \"Swift Helper Critical: \(msg)\", \"fullscreen\": false, \"bounds\": {\"x\":0,\"y\":0,\"w\":0,\"h\":0}}")
    exit(1)
}

// 1. Get Frontmost App via NSWorkspace (Reliable)
guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
    outputError("No frontmost application found via NSWorkspace")
    abort()
}

let bundleId = frontmostApp.bundleIdentifier
let appName = frontmostApp.localizedName
let pid = frontmostApp.processIdentifier

// 2. Create AXElement directly from PID (Bypasses kAXErrorAppIsTerminated on systemWide)
let axApp = AXUIElementCreateApplication(pid)

// 3. Get Focused Window from the App Element
var focusedWindow: AnyObject?
let resWin = AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focusedWindow)

if resWin != .success {
    // Often happens if app has no windows (e.g. Finder with no windows open) or just simple focus issues
    output(json: Output(
        bundleId: bundleId,
        appName: appName,
        windowTitle: nil,
        fullscreen: false,
        bounds: Bounds(x: 0, y: 0, w: 0, h: 0),
        debug: "Swift Helper: No Window Focus (Code: \(resWin.rawValue))"
    ))
}

let axWindow = focusedWindow as! AXUIElement

// 4. Get Attributes (Fullscreen, Title, Frame)

// Fullscreen
var isFullscreenVal: AnyObject?
// Try "AXFullScreen" (Most apps)
var resFull = AXUIElementCopyAttributeValue(axWindow, "AXFullScreen" as CFString, &isFullscreenVal)
var isFullscreen = (isFullscreenVal as? Bool) ?? false

// Title
var titleVal: AnyObject?
AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleVal)
let windowTitle = titleVal as? String

// Position & Size
var posVal: AnyObject?
AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &posVal)
var x: Double = 0
var y: Double = 0
if let p = posVal, CFGetTypeID(p) == AXValueGetTypeID() {
    let axVal = p as! AXValue
    var pt = CGPoint.zero
    AXValueGetValue(axVal, .cgPoint, &pt)
    x = Double(pt.x)
    y = Double(pt.y)
}

var sizeVal: AnyObject?
AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeVal)
var w: Double = 0
var h: Double = 0
if let s = sizeVal, CFGetTypeID(s) == AXValueGetTypeID() {
    let axVal = s as! AXValue
    var sz = CGSize.zero
    AXValueGetValue(axVal, .cgSize, &sz)
    w = Double(sz.width)
    h = Double(sz.height)
}

output(json: Output(
    bundleId: bundleId,
    appName: appName,
    windowTitle: windowTitle,
    fullscreen: isFullscreen,
    bounds: Bounds(x: x, y: y, w: w, h: h),
    debug: "Swift Helper: Operational (PID Strategy)"
))
