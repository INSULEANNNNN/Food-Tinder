import SwiftUI

struct LoadingCardView: View {
    @State private var phase: CGFloat = 0
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Card
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.gray.opacity(0.1))
            
            // Shimmer Animation Overlay
            GeometryReader { geo in
                Color.white.opacity(0.3)
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 200)
                            .offset(x: -200 + (phase * (geo.size.width + 200)))
                    )
            }
            
            // Placeholder Content
            VStack(alignment: .leading, spacing: 12) {
                // Title Line
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 32)
                
                // Info Line
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 60, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 40, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 80, height: 16)
                }
                
                // Address Line
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 150, height: 14)
            }
            .padding(24)
            
            // Centered Pulsing Icon
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(primaryColor.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .scaleEffect(1 + (phase * 0.2))
                                .opacity(1 - phase)
                            
                            Text("🍕")
                                .font(.system(size: 60))
                        }
                        
                        Text("กำลังค้นหาร้านอร่อย...")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .opacity(0.6)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .cornerRadius(28)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

#Preview {
    LoadingCardView()
        .frame(width: 350, height: 500)
        .padding()
}
