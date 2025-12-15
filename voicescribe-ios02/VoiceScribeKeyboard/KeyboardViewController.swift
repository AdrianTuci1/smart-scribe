//
//  KeyboardViewController.swift
//  VoiceScribeKeyboard
//
//  Created on 15.12.2025.
//

import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    override func updateViewConstraints() {
        super.updateViewConstraints()
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure we have a valid view model that can access specific keyboard functionality
        let viewModel = KeyboardViewModel(textDocumentProxy: self.textDocumentProxy)
        
        // Create the SwiftUI view
        let keyboardView = KeyboardView(viewModel: viewModel)
        
        // Host the SwiftUI view
        let hostingController = UIHostingController(rootView: keyboardView)
        hostingController.view.backgroundColor = .clear
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            hostingController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        // Request open access check or setup events
        // Note: Full Access must be enabled in Settings for network to work
        if !hasFullAccess() {
             // We might want to show a warning in the UI via the ViewModel
             viewModel.errorMessage = "Please enable 'Full Access' in Settings to use Voice Transcription."
        }
    }
    
    // Simple heuristic to check for full access (not 100% reliable but good for UI hint)
    private func hasFullAccess() -> Bool {
        return UIPasteboard.general.hasStrings || UIPasteboard.general.hasImages || true // UIPasteboard access usually requires full access
    }

    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }

    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        // We can update the view color or other UI here if needed
    }
}
