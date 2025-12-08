import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Search")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Search notes...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical)
            
            Spacer()
            
            Text("No results found")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
}
