import Foundation

protocol RestaurantServiceProtocol {
    func fetchNearbyRestaurants(lat: Double, lng: Double, radius: Double) async throws -> [GooglePlace]
}

class RestaurantService: RestaurantServiceProtocol {
    static let shared = RestaurantService()
    private init() {}
    
    func fetchNearbyRestaurants(lat: Double, lng: Double, radius: Double) async throws -> [GooglePlace] {
        // จำลองการเรียก Google Places API
        try await Task.sleep(nanoseconds: 1 * 500_000_000) // 0.5s delay
        
        // Mock Data ที่โครงสร้างเหมือน Google จะส่งมา
        return [
            GooglePlace(id: "g1", name: "ก๋วยเตี๋ยวเรือแชมป์", rating: 4.5, priceLevel: 1, distance: 0.8, address: "ใกล้เซ็นทรัล", imageUrl: "https://images.unsplash.com/photo-1552611052-33e04de081de"),
            GooglePlace(id: "g2", name: "Shabu Indy", rating: 4.2, priceLevel: 2, distance: 1.5, address: "ถนนนิมมาน", imageUrl: "https://images.unsplash.com/photo-1559847844-5315695dadae"),
            GooglePlace(id: "g3", name: "Somtum Der", rating: 4.8, priceLevel: 1, distance: 2.1, address: "ศาลาแดง", imageUrl: "https://images.unsplash.com/photo-1559847844-5315695dadae"),
            GooglePlace(id: "g4", name: "Fine Dining BKK", rating: 4.9, priceLevel: 4, distance: 5.0, address: "สุขุมวิท 24", imageUrl: "https://images.unsplash.com/photo-1473093226795-af9932fe5856")
        ]
    }
}
