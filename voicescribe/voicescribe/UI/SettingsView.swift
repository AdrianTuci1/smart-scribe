import SwiftUI

struct SettingsView: View {
    @State private var selectedCategory: SettingsCategory = .general
    
    var body: some View {
        NavigationSplitView {
            // Settings sidebar
            List(SettingsCategory.allCases, id: \.self, selection: $selectedCategory) { category in
                Label(category.displayName, systemImage: category.icon)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            // Settings content based on selected category
            Group {
                switch selectedCategory {
                case .general:
                    GeneralSettingsView()
                case .system:
                    SystemSettingsView()
                case .vibeCoding:
                    VibeCodingSettingsView()
                case .experimental:
                    ExperimentalSettingsView()
                case .account:
                    AccountSettingsView()
                case .team:
                    TeamSettingsView()
                case .plansBilling:
                    PlansBillingSettingsView()
                case .dataPrivacy:
                    DataPrivacySettingsView()
                }
            }
            .navigationTitle(selectedCategory.displayName)
            .padding()
        }
    }
}

// MARK: - Settings Categories

enum SettingsCategory: CaseIterable {
    case general
    case system
    case vibeCoding
    case experimental
    case account
    case team
    case plansBilling
    case dataPrivacy
    
    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .system:
            return "System"
        case .vibeCoding:
            return "Vibe Coding"
        case .experimental:
            return "Experimental"
        case .account:
            return "Account"
        case .team:
            return "Team"
        case .plansBilling:
            return "Plans and Billing"
        case .dataPrivacy:
            return "Data and Privacy"
        }
    }
    
    var icon: String {
        switch self {
        case .general:
            return "keyboard"
        case .system:
            return "gearshape"
        case .vibeCoding:
            return "brain.head.profile"
        case .experimental:
            return "flask"
        case .account:
            return "person.circle"
        case .team:
            return "person.2"
        case .plansBilling:
            return "creditcard"
        case .dataPrivacy:
            return "lock.shield"
        }
    }
}

// MARK: - Settings Views

struct GeneralSettingsView: View {
    @State private var pushToTalkKey = "⌃⌥⌘R"
    @State private var handsFreeModeKey = "⌃⌥⌘H"
    @State private var commandModeEnabled = true
    @State private var pasteLastTranscriptEnabled = true
    @State private var selectedMicrophone = "Auto Detect"
    @State private var selectedLanguage = "English (US)"
    
    let microphones = ["Auto Detect", "Built-in", "External Microphone 1", "External Microphone 2"]
    let languages = ["English (US)", "English (UK)", "Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese"]
    
    var body: some View {
        Form {
            // Keyboard Shortcuts Section
            Section(header: Text("Keyboard Shortcuts")) {
                // Push to Talk
                HStack {
                    Text("Push to Talk")
                    Spacer()
                    Button(pushToTalkKey) {
                        // Open dialog to change shortcut
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                }
                
                // Hands-Free Mode
                HStack {
                    Text("Hands-Free Mode")
                    Spacer()
                    Button(handsFreeModeKey) {
                        // Open dialog to change shortcut
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                }
                
                // Command Mode
                Toggle("Command Mode", isOn: $commandModeEnabled)
                
                // Paste Last Transcript
                Toggle("Paste Last Transcript", isOn: $pasteLastTranscriptEnabled)
            }
            
            // Microphone Section
            Section(header: Text("Microphone")) {
                Picker("Microphone", selection: $selectedMicrophone) {
                    ForEach(microphones, id: \.self) { microphone in
                        Text(microphone).tag(microphone)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Languages Section
            Section(header: Text("Languages")) {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct VibeCodingSettingsView: View {
    @State private var variableRecognition = true
    @State private var fileTaggingInChat = true
    
    var body: some View {
        Form {
            Section(header: Text("Vibe Coding Features")) {
                Toggle("Variable Recognition", isOn: $variableRecognition)
                Toggle("File Tagging in Chat", isOn: $fileTaggingInChat)
            }
            
            Section(header: Text("Variable Recognition")) {
                Text("Automatically recognize and highlight variables in your code")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("File Tagging")) {
                Text("Automatically tag files when mentioned in chat for better organization")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ExperimentalSettingsView: View {
    @State private var advancedVoiceCommands = false
    
    var body: some View {
        Form {
            Section(header: Text("Experimental Features")) {
                Toggle("Command Mode - Enable Advanced Voice Commands", isOn: $advancedVoiceCommands)
            }
            
            Section(header: Text("Warning")) {
                Text("These features are experimental and may cause instability. Use with caution.")
                    .foregroundColor(.orange)
            }
            
            Section(header: Text("Command Mode")) {
                Text("Enable advanced voice commands for more complex operations and automation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AccountSettingsView: View {
    @StateObject private var authService = AuthService.shared
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Form {
            Section(header: Text("Profile Information")) {
                HStack {
                    Text("First Name")
                    TextField("First Name", text: $firstName)
                }
                
                HStack {
                    Text("Last Name")
                    TextField("Last Name", text: $lastName)
                }
                
                HStack {
                    Text("Email")
                    TextField("Email", text: $email)
                }
                
                HStack {
                    Text("Profile Picture")
                    Spacer()
                    Button("Upload") {
                        // Upload profile picture
                    }
                }
            }
            
            Section(header: Text("Account Actions")) {
                Button("Sign Out") {
                    Task {
                        await authService.signOut()
                    }
                }
                
                Button("Delete Account") {
                    showingDeleteConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete account functionality
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .onAppear {
            // Load user data when view appears
            loadUserData()
        }
    }
    
    private func loadUserData() {
        if let name = authService.userName {
            let nameComponents = name.components(separatedBy: " ")
            firstName = nameComponents.first ?? ""
            lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        }
        email = authService.userEmail ?? ""
    }
}

struct TeamSettingsView: View {
    @State private var email1 = ""
    @State private var email2 = ""
    @State private var email3 = ""
    @State private var showingInviteConfirmation = false
    
    var body: some View {
        Form {
            Section(header: Text("Invite Your Teammates")) {
                HStack {
                    Text("Email 1")
                    TextField("Enter email address", text: $email1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Email 2")
                    TextField("Enter email address", text: $email2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Email 3")
                    TextField("Enter email address", text: $email3)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button("Send Invitations") {
                    sendInvitations()
                }
                .disabled(email1.isEmpty && email2.isEmpty && email3.isEmpty)
            }
            
            Section(header: Text("Team Members")) {
                Text("No team members yet")
                    .foregroundColor(.secondary)
            }
        }
        .alert("Invitations Sent", isPresented: $showingInviteConfirmation) {
            Button("OK") { }
        } message: {
            Text("Invitations have been sent to your team members.")
        }
    }
    
    private func sendInvitations() {
        // Send invitations functionality
        var emails = [String]()
        if !email1.isEmpty { emails.append(email1) }
        if !email2.isEmpty { emails.append(email2) }
        if !email3.isEmpty { emails.append(email3) }
        
        // TODO: Implement actual invitation sending logic
        print("Sending invitations to: \(emails)")
        
        // Clear fields after sending
        email1 = ""
        email2 = ""
        email3 = ""
        
        // Show confirmation
        showingInviteConfirmation = true
    }
}

struct PlansBillingSettingsView: View {
    @State private var billingCycle = "monthly"
    @State private var selectedPlan = "free"
    
    let plans = [
        Plan(id: "free", name: "Free", price: "$0", features: ["Basic transcription", "100 minutes/month"]),
        Plan(id: "basic", name: "Basic", price: "$9.99", features: ["Advanced transcription", "500 minutes/month", "Basic formatting"]),
        Plan(id: "pro", name: "Pro", price: "$19.99", features: ["Unlimited transcription", "Advanced formatting", "Priority support"]),
        Plan(id: "enterprise", name: "Enterprise", price: "Custom", features: ["Custom features", "Dedicated support", "SLA guarantee"])
    ]
    
    struct Plan {
        let id: String
        let name: String
        let price: String
        let features: [String]
    }
    
    var body: some View {
        Form {
            Section(header: Text("Billing Cycle")) {
                Picker("Billing Cycle", selection: $billingCycle) {
                    Text("Monthly").tag("monthly")
                    Text("Annual").tag("annual")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Available Plans")) {
                ForEach(plans, id: \.id) { plan in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(plan.name)
                                .font(.headline)
                            Spacer()
                            Text(billingCycle == "monthly" ? plan.price + "/mo" : plan.price + "/yr")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(plan.features, id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(feature)
                                    .font(.caption)
                            }
                        }
                        
                        if selectedPlan != plan.id {
                            Button("Select") {
                                selectedPlan = plan.id
                                // TODO: Implement plan selection logic
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Text("Current Plan")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                }
            }
            
            Section(header: Text("Billing History")) {
                Button("View Billing History") {
                    // View billing history
                }
            }
        }
    }
}

struct DataPrivacySettingsView: View {
    @State private var privacyMode = false
    @State private var contextAwareness = true
    @State private var showingDeleteConfirmation = false
    @State private var showingHardRefreshConfirmation = false
    @State private var hipaaEnabled = false
    
    var body: some View {
        Form {
            Section(header: Text("Privacy Settings")) {
                Toggle("Privacy Mode", isOn: $privacyMode)
                Toggle("Context Awareness", isOn: $contextAwareness)
            }
            
            Section(header: Text("Data Management")) {
                Button("Hard Refresh All Notes") {
                    showingHardRefreshConfirmation = true
                }
                
                Button("Delete History of All Activity") {
                    showingDeleteConfirmation = true
                }
                .foregroundColor(.red)
            }
            
            Section(header: Text("HIPAA Compliance")) {
                Toggle("Enable HIPAA", isOn: $hipaaEnabled)
                
                if hipaaEnabled {
                    Button("View and Accept HIPAA Agreement") {
                        // Show HIPAA agreement
                    }
                }
            }
        }
        .alert("Delete All Activity", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete all activity functionality
            }
        } message: {
            Text("Are you sure you want to delete all activity history? This action cannot be undone.")
        }
        .alert("Hard Refresh Notes", isPresented: $showingHardRefreshConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Refresh") {
                // Hard refresh all notes functionality
            }
        } message: {
            Text("This will refresh all your notes and may take some time. Continue?")
        }
    }
}

struct SystemSettingsView: View {
    @State private var launchAtLogin = true
    @State private var showFlowBarAlways = true
    @State private var showInDock = false
    @State private var dictationSoundEffect = true
    @State private var muteMusicWhileDictating = false
    @State private var autoAddToDirectory = true
    @State private var smartFormatting = true
    @State private var emailAutoSignature = false
    @State private var creatorMode = false
    
    var body: some View {
        Form {
            // App Settings Section
            Section(header: Text("App Settings")) {
                Toggle("Launch App at Login", isOn: $launchAtLogin)
                Toggle("Show Flow Bar at All Times", isOn: $showFlowBarAlways)
                Toggle("Show in Dock", isOn: $showInDock)
            }
            
            // Sounds Section
            Section(header: Text("Sounds")) {
                Toggle("Dictation Sound Effect", isOn: $dictationSoundEffect)
                Toggle("Mute Music While Dictating", isOn: $muteMusicWhileDictating)
            }
            
            // Extras Section
            Section(header: Text("Extras")) {
                Toggle("Auto Add to Directory", isOn: $autoAddToDirectory)
                Toggle("Smart Formatting", isOn: $smartFormatting)
                Toggle("Email Auto Signature", isOn: $emailAutoSignature)
                Toggle("Creator Mode", isOn: $creatorMode)
            }
            
            // Data Section
            Section(header: Text("Data")) {
                Button("Reset App") {
                    // Reset app functionality
                }
                .foregroundColor(.red)
            }
        }
    }
}
