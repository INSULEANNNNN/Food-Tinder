import SwiftUI
import Combine

final class MatchManager: ObservableObject {
    // เก็บรายการร้านที่ถูกใจ (Matched)
    @Published var matchedRestaurants: [GooglePlace] = []
    
    // ฟังก์ชันเพิ่มร้านที่ถูกใจ
    func addMatch(_ restaurant: GooglePlace) {
        DispatchQueue.main.async {
            if !self.matchedRestaurants.contains(where: { $0.id == restaurant.id }) {
                withAnimation {
                    self.matchedRestaurants.insert(restaurant, at: 0)
                }
            }
        }
    }
}
