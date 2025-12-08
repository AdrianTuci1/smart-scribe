import SwiftUI

struct HistoryView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("History")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            List {
                Text("Today")
                    .font(.headline)
                Text("Meeting with Team")
                Text("Project Ideas")
                
                Text("Yesterday")
                    .font(.headline)
                    .padding(.top)
                Text("Grocery List")
            }
        }
        .padding()
    }
}
