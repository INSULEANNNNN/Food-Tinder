import SwiftUI
import Combine
import CoreLocation
import Supabase
import Auth
import Realtime

struct SessionFilterUpdate: Codable {
    let filter_radius_meters: Int
    let filter_min_price: Int
    let filter_max_price: Int
    let filter_keyword: String
}

class SwipeViewModel: ObservableObject {
    @Published var restaurants: [GooglePlace] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    
    // Filter properties
    @Published var radius: Double = 10.0
    @Published var minPrice: Int = 1
    @Published var maxPrice: Int = 4 
    @Published var cuisine: String = ""
    
    private var isFiltersLoaded = false
    var matchManager: MatchManager? {
        didSet {
            setupSessionSubscription()
        }
    }
    
    private let restaurantService = RestaurantService.shared
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var sessionChannel: RealtimeChannelV2?
    
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
                    await self?.handleInitialLoad(at: location)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSessionSubscription() {
        matchManager?.$currentSessionId
            .sink { [weak self] sessionId in
                if let sessionId = sessionId {
                    self?.syncWithSession(sessionId)
                } else {
                    Task {
                        await self?.stopSessionSync()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func syncWithSession(_ sessionId: UUID) {
        Task {
            // Stop existing sync if any
            await stopSessionSync()
            
            // 1. Fetch initial session filters
            await fetchSessionFilters(sessionId: sessionId)
            
            // 2. Listen for realtime updates to this session
            let channelName = "session_filters_\(sessionId.uuidString)"
            let channel = supabase.channel(channelName)
            
            let changes = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "sessions",
                filter: "id=eq.\(sessionId.uuidString)"
            )
            
            await channel.subscribe()
            self.sessionChannel = channel
            
            // Handle changes via AsyncStream
            for await _ in changes {
                await fetchSessionFilters(sessionId: sessionId)
                await reload()
            }
        }
    }
    
    private func stopSessionSync() async {
        if let channel = sessionChannel {
            await supabase.removeChannel(channel)
        }
        sessionChannel = nil
    }
    
    private func fetchSessionFilters(sessionId: UUID) async {
        do {
            let session: FTSessionDetail = try await supabase
                .from("sessions")
                .select("filter_radius_meters, filter_min_price, filter_max_price, filter_keyword, lat, lng")
                .eq("id", value: sessionId)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.radius = Double(session.filter_radius_meters ?? 5000) / 1000.0
                self.minPrice = session.filter_min_price ?? 1
                self.maxPrice = session.filter_max_price ?? 4
                self.cuisine = session.filter_keyword ?? ""
                self.isFiltersLoaded = true
            }
        } catch {
            print("SwipeViewModel: Error fetching session filters: \(error)")
        }
    }
    
    private func getUserId() async -> String {
        do {
            let session = try await supabase.auth.session
            return session.user.id.uuidString
        } catch {
            return "default"
        }
    }
    
    private func handleInitialLoad(at location: CLLocationCoordinate2D) async {
        if !isFiltersLoaded && matchManager?.currentSessionId == nil {
            await loadPersistedFilters()
        }
        
        // Sync location to DB once per app session
        if let userIdString = try? await supabase.auth.session.user.id.uuidString, 
           let userId = UUID(uuidString: userIdString) {
            try? await UserService.shared.updateLocation(userId: userId, lat: location.latitude, lng: location.longitude)
        }
        
        await loadRestaurants(at: location)
    }
    
    @MainActor
    func loadRestaurants(at location: CLLocationCoordinate2D) async {
        guard !isLoading && restaurants.isEmpty else { return }
        
        isLoading = true
        do {
            var searchLocation = location
            
            // If in an active group session, use the fixed session location
            if let sessionId = matchManager?.currentSessionId, matchManager?.currentSessionStatus == "active" {
                print("SwipeViewModel: Active group session, fetching session location...")
                do {
                    let sessionData: FTSessionDetail = try await supabase
                        .from("sessions")
                        .select("id, created_by, status, lat, lng")
                        .eq("id", value: sessionId)
                        .single()
                        .execute()
                        .value
                    
                    if let sLat = sessionData.lat, let sLng = sessionData.lng {
                        print("SwipeViewModel: Using fixed session location: \(sLat), \(sLng)")
                        searchLocation = CLLocationCoordinate2D(latitude: sLat, longitude: sLng)
                    } else if let hostId = sessionData.created_by {
                        // Fallback to fetching host profile if session lat/lng is missing
                        let hostProfile: UserLocation = try await supabase
                            .from("users")
                            .select("id, last_latitude, last_longitude")
                            .eq("id", value: hostId)
                            .single()
                            .execute()
                            .value
                        
                        if let hLat = hostProfile.last_latitude, let hLng = hostProfile.last_longitude {
                            print("SwipeViewModel: Using host profile fallback location: \(hLat), \(hLng)")
                            searchLocation = CLLocationCoordinate2D(latitude: hLat, longitude: hLng)
                        }
                    }
                } catch {
                    print("SwipeViewModel: Could not fetch session/host location (\(error)). Falling back to local.")
                }
            }

            let fetchedRestaurants: [GooglePlace]
            
            if cuisine.isEmpty {
                fetchedRestaurants = try await restaurantService.fetchNearbyRestaurants(
                    lat: searchLocation.latitude,
                    lng: searchLocation.longitude,
                    radius: radius * 1000.0,
                    minPrice: minPrice,
                    maxPrice: maxPrice
                )
            } else {
                fetchedRestaurants = try await restaurantService.fetchByQuery(
                    query: cuisine,
                    lat: searchLocation.latitude,
                    lng: searchLocation.longitude,
                    radius: radius * 1000.0,
                    minPrice: minPrice,
                    maxPrice: maxPrice
                )
            }
            
            let swipedIds = matchManager?.swipedPlaceIds ?? []
            self.restaurants = fetchedRestaurants.filter { !swipedIds.contains($0.id) }
            self.currentIndex = 0
        } catch {
            print("SwipeViewModel: Error loading restaurants: \(error)")
        }
        isLoading = false
    }

    func applyFilters(radius: Double, minPrice: Int, maxPrice: Int, cuisine: String) {
        self.radius = radius
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.cuisine = cuisine
        
        Task {
            if let sessionId = matchManager?.currentSessionId {
                await updateSessionFilters(sessionId: sessionId)
            } else {
                await saveFilters()
            }
        }
        reload()
    }

    private func updateSessionFilters(sessionId: UUID) async {
        let update = SessionFilterUpdate(
            filter_radius_meters: Int(radius * 1000),
            filter_min_price: minPrice,
            filter_max_price: maxPrice,
            filter_keyword: cuisine
        )
        
        do {
            try await supabase
                .from("sessions")
                .update(update)
                .eq("id", value: sessionId)
                .execute()
        } catch {
            print("SwipeViewModel: Error updating group filters: \(error)")
        }
    }

    private func saveFilters() async {
        let userId = await getUserId()
        let defaults = UserDefaults.standard
        let prefix = "filter_\(userId)_"
        defaults.set(radius, forKey: prefix + "radius")
        defaults.set(minPrice, forKey: prefix + "minPrice")
        defaults.set(maxPrice, forKey: prefix + "maxPrice")
        defaults.set(cuisine, forKey: prefix + "cuisine")
    }
    
    private func loadPersistedFilters() async {
        let userId = await getUserId()
        let defaults = UserDefaults.standard
        let prefix = "filter_\(userId)_"
        
        await MainActor.run {
            if defaults.object(forKey: prefix + "radius") != nil {
                self.radius = defaults.double(forKey: prefix + "radius")
                self.minPrice = defaults.integer(forKey: prefix + "minPrice")
                self.maxPrice = defaults.integer(forKey: prefix + "maxPrice")
                self.cuisine = defaults.string(forKey: prefix + "cuisine") ?? ""
            }
            self.isFiltersLoaded = true
        }
    }

    func reload() {
        if let location = locationManager.location {
            restaurants = []
            isLoading = false
            Task {
                await loadRestaurants(at: location)
            }
        }
    }
    
    func swipe(isLike: Bool) {
        if currentIndex < restaurants.count {
            let currentRestaurant = restaurants[currentIndex]
            Task {
                await matchManager?.recordSwipe(placeId: currentRestaurant.id, isLike: isLike)
            }
            if isLike {
                matchManager?.addMatch(currentRestaurant)
            }
        }
        withAnimation {
            currentIndex += 1
        }
    }
}

struct FTSessionDetail: Codable {
    let id: UUID?
    let created_by: UUID?
    let status: String?
    let filter_radius_meters: Int?
    let filter_min_price: Int?
    let filter_max_price: Int?
    let filter_keyword: String?
    let lat: Double?
    let lng: Double?
}
