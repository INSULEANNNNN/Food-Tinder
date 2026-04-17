import SwiftUI

struct MatchView: View {
    @State private var matchedRestaurants = [
        "Sushi Zen",
        "Pasta Palace",
        "Burger King"
    ]
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationView {
            List {
                ForEach(matchedRestaurants, id: \.self) { restaurant in
                    HStack(spacing: 16) {
                        Circle()
                            .fill(primaryColor.opacity(0.1))
                            .frame(width: 50, height: 50)
                            .overlay(Text("🍴").font(.title3))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(restaurant)
                                .font(.headline)
                            Text("Matched recently")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Phase 5 Social Sharing feature
                        Button(action: {
                            shareMatch(restaurant: restaurant)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(primaryColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Matched Stores")
            .listStyle(InsetGroupedListStyle())
            .overlay {
                if matchedRestaurants.isEmpty {
                    VStack(spacing: 12) {
                        Text("No matches yet!").font(.title3).foregroundColor(.gray)
                        Text("Start swiping to find something to eat together.").font(.subheadline).foregroundColor(.gray.opacity(0.8))
                    }
                }
            }
        }
    }
    
    private func shareMatch(restaurant: String) {
        let text = "Hey! Let's eat at \(restaurant). We just matched on Food Tinder! 🍕🍟"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // This is a bit of a hack to get the UIActivityViewController to show in SwiftUI
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true, completion: nil)
        }
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
    }
}
