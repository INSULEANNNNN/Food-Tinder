import SwiftUI

struct TinderCard: View {
    let place: GooglePlace
    var onSwipe: (Bool) -> Void
    
    @State private var offset: CGSize = .zero
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image Container with fixed clipping
            GeometryReader { geo in
                AsyncImage(url: URL(string: place.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped() // ตัดส่วนที่เกินออกเพื่อให้ขนาดเท่ากันเป๊ะ
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                    }
                }
            }
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.85)]),
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
                    
                    Text(String(repeating: "฿", count: place.priceLevel))
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
            
            // Indicators
            if offset.width > 0 {
                indicator(text: "ชอบ", color: .green)
                    .position(x: 100, y: 100)
                    .opacity(Double(offset.width / 150))
            } else if offset.width < -0 {
                indicator(text: "ไม่", color: .red)
                    .position(x: 280, y: 100)
                    .opacity(Double(-offset.width / 150))
            }
        }
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 12)))
        .gesture(
            DragGesture()
                .onChanged { gesture in offset = gesture.translation }
                .onEnded { gesture in
                    if gesture.translation.width > 150 {
                        withAnimation(.easeOut(duration: 0.3)) { offset = CGSize(width: 600, height: 0) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSwipe(true) }
                    } else if gesture.translation.width < -150 {
                        withAnimation(.easeOut(duration: 0.3)) { offset = CGSize(width: -600, height: 0) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSwipe(false) }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { offset = .zero }
                    }
                }
        )
    }
    
    private func indicator(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 45, weight: .black, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(color, lineWidth: 8))
            .foregroundColor(color)
            .rotationEffect(.degrees(text == "ชอบ" ? -25 : 25))
    }
}
