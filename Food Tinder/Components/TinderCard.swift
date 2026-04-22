import SwiftUI

struct TinderCard: View {
    let place: GooglePlace
    var onSwipe: (Bool) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var currentImageIndex = 0
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .bottomLeading) {
                // Image Container
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        if !place.imageUrls.isEmpty {
                            AsyncImage(url: URL(string: place.imageUrls[currentImageIndex])) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            } placeholder: {
                                ZStack {
                                    Color.gray.opacity(0.1)
                                    ProgressView()
                                }
                            }
                        } else {
                            ZStack {
                                Color.gray.opacity(0.1)
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                        
                        // Custom Image Indicators (Dashes at the top)
                        if place.imageUrls.count > 1 {
                            HStack(spacing: 4) {
                                ForEach(0..<place.imageUrls.count, id: \.self) { index in
                                    Capsule()
                                        .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.4))
                                        .frame(height: 4)
                                }
                            }
                            .padding(.top, 10)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(place.name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", place.rating))
                                .foregroundColor(.white)
                        }
                        
                        Text("•").foregroundColor(.white.opacity(0.5))
                        
                        Text(String(repeating: "฿", count: min(place.priceLevel, 4)))
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                        
                        Text("•").foregroundColor(.white.opacity(0.5))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(String(format: "%.1f", place.distance)) กม.")
                                .foregroundColor(.white)
                        }
                    }
                    .font(.headline)
                    
                    Text(place.address)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(24)
            }
            .cornerRadius(28)
            .shadow(color: Color.black.opacity(0.15), radius: abs(offset.width) / 10 + 15, x: 0, y: 10)
            
            // Like/Dislike Overlay Indicators
            HStack {
                indicator(text: "ชอบ", color: .green)
                    .scaleEffect(1.0 + (offset.width / 500))
                    .opacity(Double(offset.width / 100))
                    .padding(25)
                Spacer()
                indicator(text: "ไม่", color: .red)
                    .scaleEffect(1.0 - (offset.width / 500))
                    .opacity(Double(-offset.width / 100))
                    .padding(25)
            }
        }
        .scaleEffect(scale)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 15)))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0) // Detects both taps and drags
                .onChanged { gesture in
                    // Only apply drag if we've moved significantly (prevents jumping on tap)
                    if abs(gesture.translation.width) > 5 {
                        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.6)) {
                            offset = gesture.translation
                            scale = 1.02
                        }
                    }
                }
                .onEnded { gesture in
                    let width = gesture.translation.width
                    let velocity = gesture.predictedEndTranslation.width
                    let threshold: CGFloat = 135
                    
                    if width > threshold || velocity > 500 {
                        swipeCard(to: 1000, isLike: true)
                    } else if width < -threshold || velocity < -500 {
                        swipeCard(to: -1000, isLike: false)
                    } else {
                        // It's a tap or a small drag
                        if abs(width) < 5 {
                            // This was a Tap!
                            handleTap(at: gesture.location)
                        }
                        
                        // Reset card position
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                            offset = .zero
                            scale = 1.0
                        }
                    }
                }
        )
    }
    
    private func handleTap(at location: CGPoint) {
        // Tapping right side (60%) goes forward, left (40%) goes back
        let screenWidth = UIScreen.main.bounds.width
        if location.x > screenWidth / 2 {
            if currentImageIndex < place.imageUrls.count - 1 {
                currentImageIndex += 1
            } else {
                currentImageIndex = 0 // Wrap around to first photo
            }
        } else {
            if currentImageIndex > 0 {
                currentImageIndex -= 1
            }
        }
    }
    
    private func swipeCard(to direction: CGFloat, isLike: Bool) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            offset = CGSize(width: direction * 1.5, height: direction / 2) 
            scale = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onSwipe(isLike)
        }
    }
    
    private func indicator(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 42, weight: .black, design: .rounded))
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color, lineWidth: 6)
            )
            .foregroundColor(color)
            .rotationEffect(.degrees(text == "ชอบ" ? -15 : 15))
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05)))
    }
}
