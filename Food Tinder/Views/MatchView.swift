import SwiftUI

struct MatchView: View {
    @EnvironmentObject var matchManager: MatchManager
    
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
                            HStack(spacing: 16) {
                                // รูปภาพจำลอง
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
                                    Text(restaurant.address)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    shareMatch(restaurant: restaurant.name)
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(primaryColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("ร้านที่ถูกใจ")
        }
    }
    
    private func shareMatch(restaurant: String) {
        let text = "เฮ้! ไปกินร้าน \(restaurant) กันเถอะ เราเพิ่ง Match กันใน Food Tinder! 🍕🍟"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
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
