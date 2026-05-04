import Foundation

class MockRestaurantService: RestaurantServiceProtocol {
    static let shared = MockRestaurantService()
    private init() {}
    
    let mockPlaces: [GooglePlace] = [
        GooglePlace(
            id: "mock-1",
            name: "Somtum Der (ส้มตำเด้อ)",
            rating: 4.5,
            priceLevel: 2,
            distance: 0.8,
            address: "5/5 Sala Daeng Rd, Silom, Bangkok",
            imageUrls: [
                "https://images.unsplash.com/photo-1565123409695-7b5ef63a2efb?q=80&w=800",
                "https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=800"
            ]
        ),
        GooglePlace(
            id: "mock-2",
            name: "Jay Fai (เจ๊ไฝ)",
            rating: 4.7,
            priceLevel: 4,
            distance: 3.2,
            address: "327 Maha Chai Rd, Samran Rat, Bangkok",
            imageUrls: [
                "https://images.unsplash.com/photo-1552611052-33e04de081de?q=80&w=800",
                "https://images.unsplash.com/photo-1562607311-477043807663?q=80&w=800"
            ]
        ),
        GooglePlace(
            id: "mock-3",
            name: "Thipsamai Pad Thai (ทิพย์สมัย ผัดไทยประตูผี)",
            rating: 4.3,
            priceLevel: 1,
            distance: 3.1,
            address: "313-315 Maha Chai Rd, Samran Rat, Bangkok",
            imageUrls: [
                "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800",
                "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800"
            ]
        ),
        GooglePlace(
            id: "mock-4",
            name: "After You Dessert Cafe",
            rating: 4.8,
            priceLevel: 2,
            distance: 1.5,
            address: "Siam Square One, Bangkok",
            imageUrls: [
                "https://images.unsplash.com/photo-1495147466023-ac3c59a647a7?q=80&w=800",
                "https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=800"
            ]
        ),
        GooglePlace(
            id: "mock-5",
            name: "The Commons Thong Lo",
            rating: 4.6,
            priceLevel: 3,
            distance: 5.2,
            address: "335 Akkhara Phat Alley, Khlong Tan Nuea, Bangkok",
            imageUrls: [
                "https://images.unsplash.com/photo-1514933651103-005eec06c04b?q=80&w=800",
                "https://images.unsplash.com/photo-1550966841-3ee71a097d81?q=80&w=800"
            ]
        ),
        GooglePlace(
            id: "mock-6",
            name: "Peppina (Sukhumvit 33)",
            rating: 4.4,
            priceLevel: 3,
            distance: 4.5,
            address: "27/1 Sukhumvit 33 Alley, Bangkok",
            imageUrls: [
                "https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=800",
                "https://images.unsplash.com/photo-1574071318508-1cdbad80ad38?q=80&w=800"
            ]
        ),
        GooglePlace(
            id: "mock-7",
            name: "Roast Coffee & Eatery",
            rating: 4.5,
            priceLevel: 2,
            distance: 2.1,
            address: "EmQuartier, Bangkok",
            imageUrls: [
                "https://images.unsplash.com/photo-1445116572660-236099ec97a0?q=80&w=800",
                "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=800"
            ]
        ),
        GooglePlace(
            id: "mock-8",
            name: "Baan Tani (บ้านตานี)",
            rating: 4.2,
            priceLevel: 2,
            distance: 1.2,
            address: "Samsen Road, Bangkok",
            imageUrls: [
                "https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?q=80&w=800",
                "https://images.unsplash.com/photo-1552566626-52f8b828add9?q=80&w=800"
            ]
        )
    ]
    
    func fetchNearbyRestaurants(lat: Double, lng: Double, radius: Double, minPrice: Int, maxPrice: Int) async throws -> [GooglePlace] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Filter by price range
        return mockPlaces.filter { $0.priceLevel >= minPrice && $0.priceLevel <= maxPrice }.shuffled()
    }
    
    func fetchByQuery(query: String, lat: Double, lng: Double, radius: Double, minPrice: Int, maxPrice: Int) async throws -> [GooglePlace] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        return mockPlaces.filter { 
            ($0.name.lowercased().contains(query.lowercased()) || $0.address.lowercased().contains(query.lowercased())) &&
            ($0.priceLevel >= minPrice && $0.priceLevel <= maxPrice)
        }
    }
    
    func fetchRestaurantDetails(placeId: String) async throws -> GooglePlace {
        if let place = mockPlaces.first(where: { $0.id == placeId }) {
            return place
        }
        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Place not found"])
    }
}
