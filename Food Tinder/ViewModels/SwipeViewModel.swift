import SwiftUI
import Combine

class SwipeViewModel: ObservableObject {
    @Published var restaurants: [GooglePlace] = [
        GooglePlace(
            id: "1",
            name: "ก๋วยเตี๋ยวเรือ อยุธยา",
            rating: 4.8,
            priceLevel: 1,
            distance: 1.2,
            address: "ปากซอย 23 กรุงเทพฯ",
            imageUrl: "https://images.unsplash.com/photo-1552611052-33e04de081de?q=80&w=1000&auto=format&fit=crop"
        ),
        GooglePlace(
            id: "2",
            name: "ส้มตำ ปูปลาร้า แซ่บอีหลี",
            rating: 4.5,
            priceLevel: 1,
            distance: 2.5,
            address: "ถนนรัชดาภิเษก",
            imageUrl: "https://images.unsplash.com/photo-1559847844-5315695dadae?q=80&w=1000&auto=format&fit=crop"
        ),
        GooglePlace(
            id: "3",
            name: "The Italian Kitchen",
            rating: 4.2,
            priceLevel: 3,
            distance: 4.8,
            address: "สยามสแควร์ วัน",
            imageUrl: "https://images.unsplash.com/photo-1473093226795-af9932fe5856?q=80&w=1000&auto=format&fit=crop"
        ),
        GooglePlace(
            id: "4",
            name: "Sushi Hana",
            rating: 4.7,
            priceLevel: 4,
            distance: 3.1,
            address: "ทองหล่อ 13",
            imageUrl: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=1000&auto=format&fit=crop"
        )
    ]
    @Published var currentIndex: Int = 0
    
    func swipe(isLike: Bool) {
        withAnimation {
            currentIndex += 1
        }
    }
}
