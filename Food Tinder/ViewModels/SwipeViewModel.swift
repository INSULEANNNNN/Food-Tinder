import SwiftUI
import Combine
import CoreLocation

class SwipeViewModel: ObservableObject {
    @Published var restaurants: [GooglePlace] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    
    var matchManager: MatchManager?
    private let restaurantService = RestaurantService.shared
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        locationManager.requestLocation()
        
        // Listen for status updates
        locationManager.$authorizationStatus
            .compactMap { $0 }
            .assign(to: &$locationStatus)
        
        // Listen for location updates
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                Task {
                    await self?.loadRestaurants(at: location)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func loadRestaurants(at location: CLLocationCoordinate2D) async {
        print("SwipeViewModel: Loading restaurants at \(location.latitude), \(location.longitude)")
        guard restaurants.isEmpty else { 
            print("SwipeViewModel: Restaurants already loaded, skipping")
            return 
        }
        
        isLoading = true
        do {
            // Fetch real restaurants using Google Places API
            let fetchedRestaurants = try await restaurantService.fetchNearbyRestaurants(
                lat: location.latitude,
                lng: location.longitude,
                radius: 5000.0 // 5km
            )
            
            // Filter out already swiped ones
            let swipedIds = matchManager?.swipedPlaceIds ?? []
            self.restaurants = fetchedRestaurants.filter { !swipedIds.contains($0.id) }
            
            print("SwipeViewModel: Found \(fetchedRestaurants.count) total, showing \(self.restaurants.count) after filtering")
        } catch {
            print("SwipeViewModel: Error loading restaurants: \(error)")
        }
        isLoading = false
    }

    func reload() {
        if let location = locationManager.location {
            currentIndex = 0
            restaurants = []
            Task {
                await loadRestaurants(at: location)
            }
        }
    }
    
    func swipe(isLike: Bool) {
        if currentIndex < restaurants.count {
            let currentRestaurant = restaurants[currentIndex]
            
            // Record swipe in Supabase
            Task {
                await matchManager?.recordSwipe(placeId: currentRestaurant.id, isLike: isLike)
            }
            
            // Local match logic (UI only)
            if isLike {
                matchManager?.addMatch(currentRestaurant)
            }
        }
        
        withAnimation {
            currentIndex += 1
        }
    }
}
