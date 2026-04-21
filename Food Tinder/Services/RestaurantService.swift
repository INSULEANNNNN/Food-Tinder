import Foundation
import CoreLocation

struct GoogleConfig {
    static let apiKey = "AIzaSyBRnHaXEYFpC6No7hklScHalpIFFyawFX0"
}

protocol RestaurantServiceProtocol {
    func fetchNearbyRestaurants(lat: Double, lng: Double, radius: Double) async throws -> [GooglePlace]
    func fetchRestaurantDetails(placeId: String) async throws -> GooglePlace
}

class RestaurantService: RestaurantServiceProtocol {
    static let shared = RestaurantService()
    private init() {}
    
    func fetchNearbyRestaurants(lat: Double, lng: Double, radius: Double) async throws -> [GooglePlace] {
        let categories = ["thai_restaurant", "japanese_restaurant", "italian_restaurant", "cafe", "pizza_restaurant", "steak_house"]
        
        return try await withThrowingTaskGroup(of: [GooglePlace].self) { group in
            for category in categories {
                group.addTask {
                    return try await self.fetchCategory(category, lat: lat, lng: lng, radius: radius)
                }
            }
            
            var allPlaces: [GooglePlace] = []
            for try await categoryPlaces in group {
                allPlaces.append(contentsOf: categoryPlaces)
            }
            
            let uniquePlaces = Array(Dictionary(grouping: allPlaces, by: { $0.id }).values.compactMap { $0.first })
            return uniquePlaces.shuffled()
        }
    }
    
    private func fetchCategory(_ type: String, lat: Double, lng: Double, radius: Double) async throws -> [GooglePlace] {
        let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(GoogleConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.addValue("places.id,places.displayName,places.rating,places.priceLevel,places.formattedAddress,places.photos,places.location", forHTTPHeaderField: "X-Goog-FieldMask")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "includedTypes": [type],
            "maxResultCount": 20,
            "locationRestriction": [
                "circle": [
                    "center": ["latitude": lat, "longitude": lng],
                    "radius": radius
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decodedResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
        let rawPlaces = decodedResponse.places ?? []
        let userLocation = CLLocation(latitude: lat, longitude: lng)
        
        return rawPlaces.filter { $0.photos != nil && ($0.rating ?? 0.0) >= 3.0 }.map { place in
            let photoUrls = place.photos?.map {
                "https://places.googleapis.com/v1/\($0.name)/media?key=\(GoogleConfig.apiKey)&maxWidthPx=400"
            } ?? []
            
            let restaurantLocation = CLLocation(latitude: place.location.latitude, longitude: place.location.longitude)
            let distanceInKm = userLocation.distance(from: restaurantLocation) / 1000.0
            
            let priceInt: Int
            switch place.priceLevel {
                case "PRICE_LEVEL_INEXPENSIVE": priceInt = 1
                case "PRICE_LEVEL_MODERATE": priceInt = 2
                case "PRICE_LEVEL_EXPENSIVE": priceInt = 3
                case "PRICE_LEVEL_VERY_EXPENSIVE": priceInt = 4
                default: priceInt = 1
            }
            
            return GooglePlace(
                id: place.id,
                name: place.displayName.text,
                rating: place.rating ?? 0.0,
                priceLevel: priceInt,
                distance: distanceInKm,
                address: place.formattedAddress,
                imageUrls: photoUrls
            )
        }
    }
    
    func fetchRestaurantDetails(placeId: String) async throws -> GooglePlace {
        let url = URL(string: "https://places.googleapis.com/v1/places/\(placeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(GoogleConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.addValue("id,displayName,rating,priceLevel,formattedAddress,photos,location", forHTTPHeaderField: "X-Goog-FieldMask")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let place = try JSONDecoder().decode(GoogleAPIPlace.self, from: data)
        
        let photoUrls = place.photos?.map {
            "https://places.googleapis.com/v1/\($0.name)/media?key=\(GoogleConfig.apiKey)&maxWidthPx=400"
        } ?? []
        
        let priceInt: Int
        switch place.priceLevel {
            case "PRICE_LEVEL_INEXPENSIVE": priceInt = 1
            case "PRICE_LEVEL_MODERATE": priceInt = 2
            case "PRICE_LEVEL_EXPENSIVE": priceInt = 3
            case "PRICE_LEVEL_VERY_EXPENSIVE": priceInt = 4
            default: priceInt = 1
        }
        
        return GooglePlace(
            id: place.id,
            name: place.displayName.text,
            rating: place.rating ?? 0.0,
            priceLevel: priceInt,
            distance: 0.0,
            address: place.formattedAddress,
            imageUrls: photoUrls
        )
    }
}

struct GooglePlacesResponse: Codable {
    let places: [GoogleAPIPlace]?
}

struct GoogleAPIPlace: Codable {
    let id: String
    let displayName: DisplayName
    let rating: Double?
    let priceLevel: String?
    let formattedAddress: String
    let photos: [GooglePhoto]?
    let location: GoogleLocation
}

struct GoogleLocation: Codable {
    let latitude: Double
    let longitude: Double
}

struct DisplayName: Codable {
    let text: String
}

struct GooglePhoto: Codable {
    let name: String
}
