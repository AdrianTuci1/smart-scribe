import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var selectedCategory: SettingsCategory
    @State private var settings = UserSettings()
    @State private var isLoading = true
    
    init(isPresented: Binding<Bool>, initialCategory: SettingsCategory = .general) {
        _isPresented = isPresented
        _selectedCategory = State(initialValue: initialCategory)
    }
    
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
                            GeneralSettingsView(settings: $settings)
                        case .system:
                            SystemSettingsView(settings: $settings)
                        case .vibeCoding:
                            VibeCodingSettingsView(settings: $settings)
                        case .experimental:
                            ExperimentalSettingsView(settings: $settings)
                        case .account:
                            AccountSettingsView()
                        case .team:
                            TeamSettingsView()
                        case .plansBilling:
                            PlansBillingSettingsView()
                        case .dataPrivacy:
                            DataPrivacySettingsView(settings: $settings)
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
    @Binding var settings: UserSettings
    @State private var capturingShortcut = false
    @State private var shortcutTarget: ShortcutTarget?
    
    let microphones = ["Auto Detect", "Built-in", "External Microphone 1", "External Microphone 2"]
    let languages = ["English (US)", "English (UK)", "Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese"]
    
    enum ShortcutTarget {
        case pushToTalk
        case handsFree
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Keyboard Shortcuts Section
            SettingsSectionView(title: "Keyboard Shortcuts") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        HStack {
                            Text("Push to Talk")
                            Spacer()
                            Button(settings.pushToTalkKey) {
                                shortcutTarget = .pushToTalk
                                capturingShortcut = true
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
                            Button(settings.handsFreeModeKey) {
                                shortcutTarget = .handsFree
                                capturingShortcut = true
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
                        TrailingToggleRow("Command Mode", isOn: $settings.commandModeEnabled)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow("Paste Last Transcript", isOn: $settings.pasteLastTranscriptEnabled)
                    }
                }
            }
            
            // Microphone Section
            SettingsSectionView(title: "Microphone") {
                SettingsRowView {
                    Picker("Microphone", selection: $settings.selectedMicrophone) {
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
                    Picker("Language", selection: $settings.selectedLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $capturingShortcut) {
            ShortcutCaptureView(isPresented: $capturingShortcut) { newShortcut in
                switch shortcutTarget {
                case .pushToTalk:
                    settings.pushToTalkKey = newShortcut
                case .handsFree:
                    settings.handsFreeModeKey = newShortcut
                case .none:
                    break
                }
            }
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
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .padding(6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(NSColor.controlBackgroundColor),
                            Color(NSColor.controlBackgroundColor).opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
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

// Toggle row with trailing switch and optional subtitle
struct TrailingToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
    }
}

struct VibeCodingSettingsView: View {
    @Binding var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionView(title: "Vibe Coding Features") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        TrailingToggleRow(
                            "Variable Recognition",
                            subtitle: "Automatically recognize and highlight variables in your code",
                            isOn: $settings.variableRecognition
                        )
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow(
                            "File Tagging in Chat",
                            subtitle: "Automatically tag files when mentioned in chat for better organization",
                            isOn: $settings.fileTaggingInChat
                        )
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct ExperimentalSettingsView: View {
    @Binding var settings: UserSettings
    
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
                    TrailingToggleRow(
                        "Command Mode - Enable Advanced Voice Commands",
                        subtitle: "Enable advanced voice commands for more complex operations and automation",
                        isOn: $settings.advancedVoiceCommands
                    )
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
                        authService.signOut()
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
    @Binding var settings: UserSettings
    @State private var showingDeleteConfirmation = false
    @State private var showingHardRefreshConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionView(title: "Privacy Settings") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        TrailingToggleRow("Privacy Mode", isOn: $settings.privacyMode)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow("Context Awareness", isOn: $settings.contextAwareness)
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
                        TrailingToggleRow("Enable HIPAA", isOn: $settings.hipaaEnabled)
                    }
                    
                    if settings.hipaaEnabled {
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
    @Binding var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // App Settings Section
            SettingsSectionView(title: "App Settings") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        TrailingToggleRow("Launch App at Login", isOn: $settings.launchAtLogin)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow("Show Flow Bar at All Times", isOn: $settings.showFlowBarAlways)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow("Show in Dock", isOn: $settings.showInDock)
                    }
                }
            }
            
            // Sounds Section
            SettingsSectionView(title: "Sounds") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        TrailingToggleRow("Dictation Sound Effect", isOn: $settings.dictationSoundEffect)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow("Mute Music While Dictating", isOn: $settings.muteMusicWhileDictating)
                    }
                }
            }
            
            // Extras Section
            SettingsSectionView(title: "Extras") {
                VStack(spacing: 0) {
                    SettingsRowView {
                        TrailingToggleRow("Auto Add to Directory", isOn: $settings.autoAddToDirectory)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow("Smart Formatting", isOn: $settings.smartFormatting)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow("Email Auto Signature", isOn: $settings.emailAutoSignature)
                    }
                    
                    Divider()
                    
                    SettingsRowView {
                        TrailingToggleRow("Creator Mode", isOn: $settings.creatorMode)
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

// MARK: - Shortcut Capture Helper

struct ShortcutCaptureView: NSViewRepresentable {
    @Binding var isPresented: Bool
    var onCapture: (String) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = CaptureView()
        view.onCapture = { shortcut in
            onCapture(shortcut)
            isPresented = false
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class CaptureView: NSView {
        var onCapture: ((String) -> Void)?
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            let shortcut = Self.describe(event: event)
            onCapture?(shortcut)
        }
        
        static func describe(event: NSEvent) -> String {
            var parts: [String] = []
            
            if event.modifierFlags.contains(.control) { parts.append("⌃") }
            if event.modifierFlags.contains(.option) { parts.append("⌥") }
            if event.modifierFlags.contains(.command) { parts.append("⌘") }
            if event.modifierFlags.contains(.shift) { parts.append("⇧") }
            
            let key = event.charactersIgnoringModifiers?.uppercased() ?? ""
            parts.append(key)
            
            return parts.joined()
        }
    }
}
