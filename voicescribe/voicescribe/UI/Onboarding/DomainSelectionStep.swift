import SwiftUI

struct DomainSelectionStep: View {
    var nextAction: () -> Void
    @Binding var selectedDomains: Set<String>
    
    let domains = [
        ("Medical", "stethoscope"),
        ("Legal", "text.book.closed"),
        ("Technical/Coding", "chevron.left.forwardslash.chevron.right"),
        ("Business", "briefcase"),
        ("Academic", "graduationcap"),
        ("Creative Writing", "pencil.tip"),
        ("General", "text.bubble")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Tailor Your Experience")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select the domains you'll be writing in most often.\nThis helps us optimize accurate terminology.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 15) {
                ForEach(domains, id: \.0) { domain, icon in
                    Button(action: {
                        toggleDomain(domain)
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: icon)
                                .font(.system(size: 30))
                                .foregroundColor(selectedDomains.contains(domain) ? .white : .blue)
                            
                            Text(domain)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundColor(selectedDomains.contains(domain) ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedDomains.contains(domain) ? Color.blue : Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedDomains.contains(domain) ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Continue") {
                nextAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedDomains.isEmpty)
        }
        .padding(40)
    }
    
    private func toggleDomain(_ domain: String) {
        if selectedDomains.contains(domain) {
            selectedDomains.remove(domain)
        } else {
            selectedDomains.insert(domain)
        }
    }
}


struct DomainSelectionStep_Previews: PreviewProvider {
    static var previews: some View {
        DomainSelectionStep(nextAction: {}, selectedDomains: .constant([]))
            .frame(width: 600, height: 500)
    }
}
