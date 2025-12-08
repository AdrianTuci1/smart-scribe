import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var selectedCategory: SettingsCategory = .general
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // Settings panel
            HStack(spacing: 0) {
                // Settings sidebar
                VStack(alignment: .leading, spacing: 4) {
                    // Header with close button
                    HStack {
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 16)
                    
                    ForEach(SettingsCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .frame(width: 20)
                                    .foregroundColor(selectedCategory == category ? .accentColor : .secondary)
                                Text(category.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedCategory == category ? Color.accentColor.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .frame(width: 220)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Settings content based on selected category
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        Text(selectedCategory.displayName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 20)
                        
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
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(width: 800, height: 600)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Settings Overlay Modifier

struct SettingsOverlay: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                SettingsView(isPresented: $isPresented)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    func settingsOverlay(isPresented: Binding<Bool>) -> some View {
        modifier(SettingsOverlay(isPresented: isPresented))
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
        VStack(alignment: .leading, spacing: 20) {
            // Keyboard Shortcuts Section
            SettingsSectionView(title: "Keyboard Shortcuts") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        HStack {
                            Text("Push to Talk")
                            Spacer()
                            Button(pushToTalkKey) {
                                // Open dialog to change shortcut
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.tertiaryLabelColor).opacity(0.2))
                            .cornerRadius(4)
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        HStack {
                            Text("Hands-Free Mode")
                            Spacer()
                            Button(handsFreeModeKey) {
                                // Open dialog to change shortcut
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.tertiaryLabelColor).opacity(0.2))
                            .cornerRadius(4)
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Command Mode", isOn: $commandModeEnabled)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Paste Last Transcript", isOn: $pasteLastTranscriptEnabled)
                    }
                }
            }
            
            // Microphone Section
            SettingsSectionView(title: "Microphone") {
                SettingsRowView {
                    Picker("Microphone", selection: $selectedMicrophone) {
                        ForEach(microphones, id: \.self) { microphone in
                            Text(microphone).tag(microphone)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Languages Section
            SettingsSectionView(title: "Languages") {
                SettingsRowView {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Reusable Settings Components

struct SettingsSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        }
    }
}

struct SettingsRowView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

struct VibeCodingSettingsView: View {
    @State private var variableRecognition = true
    @State private var fileTaggingInChat = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionView(title: "Vibe Coding Features") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Variable Recognition", isOn: $variableRecognition)
                            Text("Automatically recognize and highlight variables in your code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("File Tagging in Chat", isOn: $fileTaggingInChat)
                            Text("Automatically tag files when mentioned in chat for better organization")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct ExperimentalSettingsView: View {
    @State private var advancedVoiceCommands = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Warning Section
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("These features are experimental and may cause instability. Use with caution.")
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 0.5)
            )
            
            SettingsSectionView(title: "Experimental Features") {
                SettingsRowView {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Command Mode - Enable Advanced Voice Commands", isOn: $advancedVoiceCommands)
                        Text("Enable advanced voice commands for more complex operations and automation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
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
        VStack(alignment: .leading, spacing: 20) {
            // User Profile Header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 64, height: 64)
                    
                    Text(getInitials())
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.userName ?? "User")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(authService.userEmail ?? "user@example.com")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
            
            SettingsSectionView(title: "Profile Information") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        HStack {
                            Text("First Name")
                                .frame(width: 100, alignment: .leading)
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        HStack {
                            Text("Last Name")
                                .frame(width: 100, alignment: .leading)
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        HStack {
                            Text("Email")
                                .frame(width: 100, alignment: .leading)
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        HStack {
                            Text("Profile Picture")
                            Spacer()
                            Button("Upload") {
                                // Upload profile picture
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            SettingsSectionView(title: "Account Actions") {
                VStack(spacing: 0) {
                    Button(action: {
                        Task {
                            await authService.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out")
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.primary)
                    
                    Divider()
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.red)
                }
            }
            
            Spacer()
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
            loadUserData()
        }
    }
    
    private func getInitials() -> String {
        guard let name = authService.userName, !name.isEmpty else {
            return "U"
        }
        
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components.first?.first ?? Character("U"))\(components.last?.first ?? Character(""))"
        } else {
            return String(name.prefix(1)).uppercased()
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
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionView(title: "Invite Your Teammates") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        HStack {
                            Text("Email 1")
                                .frame(width: 60, alignment: .leading)
                            TextField("Enter email address", text: $email1)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        HStack {
                            Text("Email 2")
                                .frame(width: 60, alignment: .leading)
                            TextField("Enter email address", text: $email2)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        HStack {
                            Text("Email 3")
                                .frame(width: 60, alignment: .leading)
                            TextField("Enter email address", text: $email3)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        HStack {
                            Spacer()
                            Button("Send Invitations") {
                                sendInvitations()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(email1.isEmpty && email2.isEmpty && email3.isEmpty)
                        }
                    }
                }
            }
            
            SettingsSectionView(title: "Team Members") {
                SettingsRowView {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.secondary)
                        Text("No team members yet")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            
            Spacer()
        }
        .alert("Invitations Sent", isPresented: $showingInviteConfirmation) {
            Button("OK") { }
        } message: {
            Text("Invitations have been sent to your team members.")
        }
    }
    
    private func sendInvitations() {
        var emails = [String]()
        if !email1.isEmpty { emails.append(email1) }
        if !email2.isEmpty { emails.append(email2) }
        if !email3.isEmpty { emails.append(email3) }
        
        print("Sending invitations to: \(emails)")
        
        email1 = ""
        email2 = ""
        email3 = ""
        
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
        VStack(alignment: .leading, spacing: 20) {
            // Billing Cycle Section
            SettingsSectionView(title: "Billing Cycle") {
                SettingsRowView {
                    Picker("Billing Cycle", selection: $billingCycle) {
                        Text("Monthly").tag("monthly")
                        Text("Annual").tag("annual")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }
            }
            
            // Available Plans Section
            SettingsSectionView(title: "Available Plans") {
                VStack(spacing: 12) {
                    ForEach(plans, id: \.id) { plan in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(plan.name)
                                    .font(.headline)
                                Spacer()
                                Text(billingCycle == "monthly" ? plan.price + "/mo" : plan.price + "/yr")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(plan.features, id: \.self) { feature in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text(feature)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            
                            if selectedPlan != plan.id {
                                Button("Select Plan") {
                                    selectedPlan = plan.id
                                }
                                .buttonStyle(.bordered)
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Current Plan")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(6)
                            }
                        }
                        .padding(16)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedPlan == plan.id ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: selectedPlan == plan.id ? 2 : 0.5)
                        )
                    }
                }
            }
            
            // Billing History Section  
            SettingsSectionView(title: "Billing History") {
                Button(action: {
                    // View billing history
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("View Billing History")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.primary)
            }
            
            Spacer()
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
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionView(title: "Privacy Settings") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        Toggle("Privacy Mode", isOn: $privacyMode)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Context Awareness", isOn: $contextAwareness)
                    }
                }
            }
            
            SettingsSectionView(title: "Data Management") {
                VStack(spacing: 0) {
                    Button(action: {
                        showingHardRefreshConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Hard Refresh All Notes")
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.primary)
                    
                    Divider()
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete History of All Activity")
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.red)
                }
            }
            
            SettingsSectionView(title: "HIPAA Compliance") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        Toggle("Enable HIPAA", isOn: $hipaaEnabled)
                    }
                    
                    if hipaaEnabled {
                        Divider()
                        
                        Button(action: {
                            // Show HIPAA agreement
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("View and Accept HIPAA Agreement")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.primary)
                    }
                }
            }
            
            Spacer()
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
        VStack(alignment: .leading, spacing: 20) {
            // App Settings Section
            SettingsSectionView(title: "App Settings") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        Toggle("Launch App at Login", isOn: $launchAtLogin)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Show Flow Bar at All Times", isOn: $showFlowBarAlways)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Show in Dock", isOn: $showInDock)
                    }
                }
            }
            
            // Sounds Section
            SettingsSectionView(title: "Sounds") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        Toggle("Dictation Sound Effect", isOn: $dictationSoundEffect)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Mute Music While Dictating", isOn: $muteMusicWhileDictating)
                    }
                }
            }
            
            // Extras Section
            SettingsSectionView(title: "Extras") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        Toggle("Auto Add to Directory", isOn: $autoAddToDirectory)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Smart Formatting", isOn: $smartFormatting)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Email Auto Signature", isOn: $emailAutoSignature)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        Toggle("Creator Mode", isOn: $creatorMode)
                    }
                }
            }
            
            // Data Section
            SettingsSectionView(title: "Data") {
                Button(action: {
                    // Reset app functionality
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset App")
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.red)
            }
            
            Spacer()
        }
    }
}
