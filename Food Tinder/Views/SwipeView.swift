import SwiftUI

struct SwipeView: View {
    @StateObject var viewModel = SwipeViewModel()
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Explore")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 255/255, green: 87/255, blue: 51/255))
                Spacer()
                Button(action: {
                    // Open Filter
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Card Stack Container
            ZStack {
                if viewModel.currentIndex < viewModel.restaurants.count {
                    let range = viewModel.currentIndex..<min(viewModel.currentIndex + 2, viewModel.restaurants.count)
                    
                    ForEach(Array(range).reversed(), id: \.self) { index in
                        TinderCard(place: viewModel.restaurants[index]) { isLike in
                            viewModel.swipe(isLike: isLike)
                        }
                        .aspectRatio(0.75, contentMode: .fit) // กำหนดอัตราส่วนให้เท่ากันทุกใบ (3:4)
                        .padding(.horizontal, 16)
                    }
                } else {
                    // Empty State
                    VStack(spacing: 20) {
                        Text("หมดแล้วจ้า! 🍽️")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("ไม่เหลือร้านอาหารในพื้นที่ของคุณแล้ว")
                            .foregroundColor(.gray)
                        Button("เริ่มใหม่") {
                            viewModel.currentIndex = 0
                        }
                        .fontWeight(.bold)
                        .padding()
                        .background(Color(red: 255/255, green: 87/255, blue: 51/255))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Footer Control Buttons
            if viewModel.currentIndex < viewModel.restaurants.count {
                HStack(spacing: 45) {
                    Button(action: {
                        viewModel.swipe(isLike: false)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 70, height: 70)
                            .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.1), radius: 10))
                    }
                    
                    Button(action: {
                        viewModel.swipe(isLike: true)
                    }) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                            .frame(width: 70, height: 70)
                            .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.1), radius: 10))
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color.gray.opacity(0.02).ignoresSafeArea())
    }
}

struct SwipeView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeView()
    }
}
