import SwiftUI

struct MatchView: View {
    @EnvironmentObject var matchManager: MatchManager
    @State private var selectedRestaurant: GooglePlace?
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationView {
            ZStack {
                if matchManager.matchedRestaurants.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text("ยังไม่มีร้านที่ถูกใจ")
                            .font(.title3.bold())
                            .foregroundColor(.gray)
                        
                        Text("ลองปัดขวาในหน้าร้านอาหารเพื่อบันทึกร้านที่คุณสนใจไว้ที่นี่")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(matchManager.matchedRestaurants) { restaurant in
                            Button(action: {
                                selectedRestaurant = restaurant
                            }) {
                                HStack(spacing: 16) {
                                    AsyncImage(url: URL(string: restaurant.imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.1)
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(restaurant.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(restaurant.address)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        shareMatch(restaurant: restaurant)
                                    }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(primaryColor)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await matchManager.removeMatch(restaurant)
                                    }
                                } label: {
                                    Label("ลบ", systemImage: "trash.fill")
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("ร้านที่ถูกใจ")
            .sheet(item: $selectedRestaurant) { restaurant in
                RestaurantDetailView(restaurant: restaurant)
            }
        }
    }
    
    private func shareMatch(restaurant: GooglePlace) {
        let mapURL = "https://www.google.com/maps/search/?api=1&query=\(restaurant.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&query_place_id=\(restaurant.id)"
        
        let text = """
        Check out \(restaurant.name) on Food Tinder! 🍕 
        Rating: \(restaurant.rating) ⭐
        Address: \(restaurant.address)
        
        View on Maps: \(mapURL)
        """
        
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            if let popoverController = av.popoverPresentationController {
                popoverController.sourceView = topVC.view
                popoverController.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            topVC.present(av, animated: true, completion: nil)
        }
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
    }
}
