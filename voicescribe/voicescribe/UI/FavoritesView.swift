import SwiftUI

struct FavoritesView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Favorites")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            List {
                Text("No favorites yet")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
