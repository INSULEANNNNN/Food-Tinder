import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: GooglePlace
    @Environment(\.dismiss) var dismiss
    
    @State private var currentImageIndex = 0
    @State private var isLoading = false
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Large Header Image Carousel
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentImageIndex) {
                        ForEach(0..<restaurant.imageUrls.count, id: \.self) { index in
                            AsyncImage(url: URL(string: restaurant.imageUrls[index])) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.1)
                            }
                            .frame(height: 400)
                            .clipped()
                            .tag(index)
                        }
                    }
                    .frame(height: 400)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    
                    // Close Button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                    .frame(height: 400)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text(restaurant.name)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", restaurant.rating))
                                    .fontWeight(.semibold)
                            }
                            
                            Text("•").foregroundColor(.gray)
                            
                            Text(restaurant.priceString)
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                            
                            Text("•").foregroundColor(.gray)
                            
                            Text("Restaurant")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Divider()
                    
                    // Location Section
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Address", systemImage: "mappin.and.ellipse")
                            .font(.headline)
                        
                        Text(restaurant.address)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: openInMaps) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Get Directions")
                            }
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(primaryColor.opacity(0.1))
                            .foregroundColor(primaryColor)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Share Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Love this place?")
                            .font(.headline)
                        
                        Button(action: shareRestaurant) {
                            Label("Share with friends", systemImage: "square.and.arrow.up")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private func openInMaps() {
        let encodedName = restaurant.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let googleMapsAppURL = URL(string: "comgooglemaps://?q=\(encodedName)&center=0,0&zoom=15&views=traffic")!
        let googleMapsWebURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedName)&query_place_id=\(restaurant.id)")!
        
        if UIApplication.shared.canOpenURL(googleMapsAppURL) {
            UIApplication.shared.open(googleMapsAppURL)
        } else {
            UIApplication.shared.open(googleMapsWebURL)
        }
    }
    
    private func shareRestaurant() {
        let mapURL = "https://www.google.com/maps/search/?api=1&query=\(restaurant.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&query_place_id=\(restaurant.id)"
        
        let text = """
        Check out \(restaurant.name) on Food Tinder! 🍕 
        Rating: \(restaurant.rating) ⭐
        Address: \(restaurant.address)
        
        View on Maps: \(mapURL)
        """
        
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // Find the topmost view controller to present the share sheet
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
