import SwiftUI
import Combine

class SwipeViewModel: ObservableObject {
    @Published var restaurants: [GooglePlace] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    
    var matchManager: MatchManager?
    private let restaurantService = RestaurantService.shared
    
    init() {
        Task {
            await loadRestaurants()
        }
    }
    
    @MainActor
    func loadRestaurants() async {
        isLoading = true
        do {
            // ดึงข้อมูลจริงจาก Service (Google Places Mock)
            self.restaurants = try await restaurantService.fetchNearbyRestaurants(lat: 13.7563, lng: 100.5018, radius: 5.0)
        } catch {
            print("Error loading restaurants: \(error)")
        }
        isLoading = false
    }
    
    func swipe(isLike: Bool) {
        if isLike {
            if currentIndex < restaurants.count {
                let currentRestaurant = restaurants[currentIndex]
                matchManager?.addMatch(currentRestaurant)
            }
        }
        
        withAnimation {
            currentIndex += 1
        }
    }
}
