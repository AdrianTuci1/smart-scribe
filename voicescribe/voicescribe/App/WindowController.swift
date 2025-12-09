import Cocoa
import SwiftUI

class WindowController: NSWindowController, NSWindowDelegate {
    private var titleBarAccessoryViewController: NSTitlebarAccessoryViewController?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Set window delegate
        window?.delegate = self
        
        // Setup window style for transparent title bar
        setupWindowStyle()
    }
    
    private func setupWindowStyle() {
        guard let window = window else { return }
        
        // Configure window for transparent title bar with full-size content
        window.styleMask.insert(.titled)
        window.styleMask.insert(.closable)
        window.styleMask.insert(.miniaturizable)
        window.styleMask.insert(.resizable)
        window.styleMask.insert(.fullSizeContentView)
        
        // Make title bar transparent - content extends into title bar area
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = ""
        
        // Set the window background to match
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // Add the toolbar accessory view for collapse button and user menu
        setupTitlebarAccessory()
    }
    
    private func setupTitlebarAccessory() {
        guard let window = window else { return }
        
        // Create the accessory view with collapse button and user menu
        let accessoryView = TitleBarAccessoryView()
        let hostingView = NSHostingView(rootView: accessoryView)
        hostingView.frame = NSRect(x: 0, y: 0, width: window.frame.width, height: 52)
        
        // Create accessory view controller
        let accessoryViewController = NSTitlebarAccessoryViewController()
        accessoryViewController.view = hostingView
        accessoryViewController.layoutAttribute = .top
        accessoryViewController.fullScreenMinHeight = 52
        
        // Add to window
        window.addTitlebarAccessoryViewController(accessoryViewController)
        titleBarAccessoryViewController = accessoryViewController
    }
    
    func windowDidResize(_ notification: Notification) {
        // Update accessory view width on resize
        if let accessory = titleBarAccessoryViewController,
           let window = window {
            accessory.view.frame.size.width = window.frame.width
        }
    }
}

// Title bar accessory view containing collapse button and user menu
struct TitleBarAccessoryView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Spacer for traffic light buttons (approximately 78pt on macOS)
            Spacer()
                .frame(width: 78)
            
            // Collapse button right after traffic lights
            CollapsibleSidebarButton()
            
            Spacer()
            
            // User menu on the right
            UserMenuView()
                .padding(.trailing, 16)
        }
        .frame(height: 52)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// Custom view for the collapse button
struct CollapsibleSidebarButton: View {
    @State private var isCollapsed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isCollapsed.toggle()
                // Post notification to inform sidebar about state change
                NotificationCenter.default.post(
                    name: NSNotification.Name("SidebarToggle"),
                    object: nil,
                    userInfo: ["isCollapsed": isCollapsed]
                )
            }
        }) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 32, height: 32)
        .help("Toggle Sidebar")
    }
}
