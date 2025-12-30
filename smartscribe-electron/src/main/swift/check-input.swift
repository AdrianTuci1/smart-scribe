import ApplicationServices
import Foundation

// Define missing constant if not available, or use raw string
let kAXEditableAttribute = "AXEditable" as CFString

func attr<T>(_ element: AXUIElement, _ key: CFString) -> T? {
    var value: AnyObject?
    let err = AXUIElementCopyAttributeValue(element, key, &value)
    return err == .success ? value as? T : nil
}

func run() {
    let systemWide = AXUIElementCreateSystemWide()

    // kAXFocusedUIElementAttribute is usually defined but if it fails, cast it or use string
    // In CoreFoundation/ApplicationServices it should be present.
    // If "cannot convert String to CFString", it means it sees the constant as String or I need to cast "AXFocusedUIElement"
    
    guard let focusedElement: AXUIElement =
        attr(systemWide, kAXFocusedUIElementAttribute as CFString) else {
        print("false")
        return
    }

    // Check editable
    let editable: Bool = attr(focusedElement, kAXEditableAttribute) ?? false
    
    // User logic: if NOT editable, return false immediately
    guard editable else {
        print("false")
        return
    }

    // Check role
    let role: String = attr(focusedElement, kAXRoleAttribute as CFString) ?? ""

    let allowedRoles: Set<String> = [
        "AXTextField",
        "AXTextArea",
        "AXTextView",
        "AXSearchField",
        "AXComboBox",
        "AXWebArea",
        "AXRichTextView"
    ]
    
    if allowedRoles.contains(role) {
        print("true")
    } else {
        // If it's editable but not in the list, we assume false based on user req,
        // (or maybe print true because it IS editable? User code had strict check.)
        // User code: return allowedRoles.contains(role)
        print("false")
    }
}

// Run
run()
