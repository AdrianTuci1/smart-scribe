import ApplicationServices
import Foundation

// Define constants
let kAXEditableAttribute = "AXEditable" as CFString

func attr<T>(_ element: AXUIElement, _ key: CFString) -> T? {
    var value: AnyObject?
    let err = AXUIElementCopyAttributeValue(element, key, &value)
    return err == .success ? value as? T : nil
}

func run() {
    let systemWide = AXUIElementCreateSystemWide()

    // Get focused element
    guard let focusedElement: AXUIElement =
        attr(systemWide, kAXFocusedUIElementAttribute as CFString) else {
        print("false (No focused element found - Check Permissions?)")
        return
    }

    // 1. Check strict AXEditable attribute
    let editable: Bool = attr(focusedElement, kAXEditableAttribute) ?? false
    if editable {
        print("true")
        return
    }

    // 2. Role-based fallback
    let role: String = attr(focusedElement, kAXRoleAttribute as CFString) ?? "Unknown"
    
    let textInputRoles: Set<String> = [
        "AXTextField",
        "AXTextArea",
        "AXTextView",
        "AXSearchField",
        "AXComboBox",
        "AXRichTextView",
        "AXWebArea",    // Browsers
        "AXGroup"       // Some Electron apps / Custom UI wrappers just expose generic groups
    ]
    
    if textInputRoles.contains(role) {
        print("true")
        return
    }

    // Debug failure
    print("false (Role: \(role), Editable: \(editable))")
}

run()
