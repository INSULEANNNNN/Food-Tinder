import SwiftUI

struct TinderCard: View {
    let place: GooglePlace
    var onSwipe: (Bool) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .bottomLeading) {
                // Image Container
                GeometryReader { geo in
                    AsyncImage(url: URL(string: place.imageUrl)) { image in
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
            // Dynamic Shadow: ยิ่งลากไกล เงาน้อยลงเพื่อให้ดูเหมือนลอยขึ้น
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
        // 3D Rotation Effect
        .rotation3DEffect(
            .degrees(Double(offset.width / 10)),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.8
        )
        .rotationEffect(.degrees(Double(offset.width / 15)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // การเด้งขณะลาก (Springy Follow)
                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.6, blendDuration: 0.2)) {
                        offset = gesture.translation
                        rotation = Double(gesture.translation.width / 15)
                        scale = 1.02 // ขยายเล็กน้อยตอนดึง
                    }
                }
                .onEnded { gesture in
                    let velocity = gesture.predictedEndTranslation.width
                    let threshold: CGFloat = 135
                    
                    if gesture.translation.width > threshold || velocity > 500 {
                        // Swipe Right (Like) - ปลิวหายไปอย่างรวดเร็ว
                        swipeCard(to: 1000, isLike: true)
                    } else if gesture.translation.width < -threshold || velocity < -500 {
                        // Swipe Left (Dislike)
                        swipeCard(to: -1000, isLike: false)
                    } else {
                        // เด้งกลับเข้ากลางแบบแรงๆ (Snap back)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.55, blendDuration: 0.3)) {
                            offset = .zero
                            rotation = 0
                            scale = 1.0
                        }
                    }
                }
        )
    }
    
    private func swipeCard(to direction: CGFloat, isLike: Bool) {
        // ปรับทิศทางให้ปลิวหายไปไกลขึ้นเพื่อให้พ้นขอบจอแน่นอน
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3)) {
            offset = CGSize(width: direction * 1.5, height: direction / 2) 
            rotation = Double(direction / 5)
            scale = 0.5
        }
        
        // รอให้ Animation ปลิวไปไกลพอสมควรค่อยเปลี่ยน Data
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
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
            )
    }
}
