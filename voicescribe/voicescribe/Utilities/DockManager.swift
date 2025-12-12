import Foundation
import AppKit
import Combine

/// Manager for detecting and monitoring dock state changes
/// This helps position UI elements correctly relative to the dock
class DockManager: ObservableObject {
    static let shared = DockManager()
    
    private var dockObserver: NSObjectProtocol?
    private var notificationObserver: NSObjectProtocol?
    
    @Published var dockHeight: CGFloat = 0
    @Published var dockIsHidden: Bool = false
    @Published var dockPosition: DockPosition = .bottom
    
    enum DockPosition: Sendable, Equatable {
        case bottom
        case left
        case right
    }
    
    private init() {
        setupDockMonitoring()
        updateDockInfo()
    }
    
    deinit {
        stopDockMonitoring()
    }
    
    /// Sets up monitoring for dock changes
    private func setupDockMonitoring() {
        // Monitor dock configuration changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDockInfo()
        }
        
        // Also set up a timer to periodically check dock state
        // This helps catch dock position/hiding changes that might not trigger notifications
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateDockInfo()
        }
    }
    
    /// Stops monitoring dock changes
    private func stopDockMonitoring() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }
    
    /// Updates dock information
    func updateDockInfo() {
        // Execute dock commands on a background queue to avoid blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get dock orientation
            let orientationTask = Process()
            orientationTask.launchPath = "/usr/bin/defaults"
            orientationTask.arguments = ["read", "com.apple.dock", "orientation"]
            
            let pipe = Pipe()
            orientationTask.standardOutput = pipe
            
            do {
                try orientationTask.run()
                orientationTask.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let orientationOutput = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "bottom"
                
                // Determine dock position
                let newPosition: DockPosition
                switch orientationOutput {
                case "left":
                    newPosition = .left
                case "right":
                    newPosition = .right
                default:
                    newPosition = .bottom
                }
                
                // Check if dock is hidden
                let autohideTask = Process()
                autohideTask.launchPath = "/usr/bin/defaults"
                autohideTask.arguments = ["read", "com.apple.dock", "autohide"]
                let pipe2 = Pipe()
                autohideTask.standardOutput = pipe2
                try autohideTask.run()
                autohideTask.waitUntilExit()
                
                let data2 = pipe2.fileHandleForReading.readDataToEndOfFile()
                let autohideOutput = String(data: data2, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
                let dockIsHiddenValue = autohideOutput == "1"
                
                // Get dock height (only relevant for bottom position)
                var dockHeightValue: CGFloat = 0
                switch newPosition {
                case .bottom:
                    let tileSizeTask = Process()
                    tileSizeTask.launchPath = "/usr/bin/defaults"
                    tileSizeTask.arguments = ["read", "com.apple.dock", "tilesize"]
                    let pipe3 = Pipe()
                    tileSizeTask.standardOutput = pipe3
                    try tileSizeTask.run()
                    tileSizeTask.waitUntilExit()
                    
                    let data3 = pipe3.fileHandleForReading.readDataToEndOfFile()
                    let tilesizeOutput = String(data: data3, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "50"
                    
                    if let tileSize = Int(tilesizeOutput) {
                        // Dock height is roughly tile size + some margin
                        dockHeightValue = CGFloat(tileSize + 15)
                    } else {
                        dockHeightValue = 65 // Default dock height
                    }
                case .left, .right:
                    // No height calculation needed for side dock positions
                    break
                }
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.dockPosition = newPosition
                    self.dockIsHidden = dockIsHiddenValue
                    self.dockHeight = dockHeightValue
                }
            } catch {
                print("Error updating dock info: \(error)")
                // Set default values on main thread
                DispatchQueue.main.async {
                    self.dockPosition = .bottom
                    self.dockIsHidden = false
                    self.dockHeight = 65
                }
            }
        }
    }
    
    /// Gets the recommended bottom margin for floating UI elements
    /// Returns 8px above dock if visible, or 8px above screen bottom if dock is hidden
    func getRecommendedBottomMargin() -> CGFloat {
        return dockIsHidden ? 8 : (dockHeight + 8)
    }
    
    /// Gets the dock height (0 if dock is hidden or not at bottom)
    func getDockHeight() -> CGFloat {
        if dockIsHidden {
            return 0
        }
        
        switch dockPosition {
        case .bottom:
            return dockHeight
        case .left, .right:
            return 0
        }
    }
}