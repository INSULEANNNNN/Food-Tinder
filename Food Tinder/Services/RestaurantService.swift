import Foundation
import CoreLocation

struct GoogleConfig {
    static let apiKey = "AIzaSyBRnHaXEYFpC6No7hklScHalpIFFyawFX0"
}

protocol RestaurantServiceProtocol {
    func fetchNearbyRestaurants(lat: Double, lng: Double, radius: Double, minPrice: Int, maxPrice: Int) async throws -> [GooglePlace]
    func fetchByQuery(query: String, lat: Double, lng: Double, radius: Double, minPrice: Int, maxPrice: Int) async throws -> [GooglePlace]
    func fetchRestaurantDetails(placeId: String) async throws -> GooglePlace
}

class RestaurantService: RestaurantServiceProtocol {
    static let shared = RestaurantService()
    private init() {}
    
    private func mapPriceLevel(_ level: Int?) -> String? {
        guard let level = level else { return nil }
        switch level {
            case 1: return "PRICE_LEVEL_INEXPENSIVE"
            case 2: return "PRICE_LEVEL_MODERATE"
            case 3: return "PRICE_LEVEL_EXPENSIVE"
            case 4: return "PRICE_LEVEL_VERY_EXPENSIVE"
            default: return nil
        }
    }
    
    func fetchByQuery(query: String, lat: Double, lng: Double, radius: Double, minPrice: Int, maxPrice: Int) async throws -> [GooglePlace] {
        let url = URL(string: "https://places.googleapis.com/v1/places:searchText")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(GoogleConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.addValue("places.id,places.displayName,places.rating,places.priceLevel,places.formattedAddress,places.photos,places.location", forHTTPHeaderField: "X-Goog-FieldMask")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "textQuery": query,
            "maxResultCount": 20,
            "locationBias": [
                "circle": [
                    "center": ["latitude": lat, "longitude": lng],
                    "radius": radius
                ]
            ]
        ]
        
        // Use all levels in range for text search
        let levels = (minPrice...maxPrice).compactMap { mapPriceLevel($0) }
        if !levels.isEmpty {
            body["priceLevels"] = levels
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("RestaurantService: SearchText Error - Status \(httpResponse.statusCode)")
            return []
        }
        
        let decodedResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
        let rawPlaces = decodedResponse.places ?? []
        return processRawPlaces(rawPlaces, userLat: lat, userLng: lng, radius: radius, minPrice: minPrice, maxPrice: maxPrice)
    }
    
    private func processRawPlaces(_ rawPlaces: [GoogleAPIPlace], userLat: Double, userLng: Double, radius: Double, minPrice: Int, maxPrice: Int) -> [GooglePlace] {
        let userLocation = CLLocation(latitude: userLat, longitude: userLng)
        let radiusInKm = radius / 1000.0
        
        return rawPlaces.map { place in
            let photoUrls = place.photos?.map {
                "https://places.googleapis.com/v1/\($0.name)/media?key=\(GoogleConfig.apiKey)&maxWidthPx=400"
            } ?? []
            
            let restaurantLocation = CLLocation(latitude: place.location.latitude, longitude: place.location.longitude)
            let distanceInKm = userLocation.distance(from: restaurantLocation) / 1000.0
            
            let priceInt: Int
            if let level = place.priceLevel {
                switch level {
                    case "PRICE_LEVEL_INEXPENSIVE": priceInt = 1
                    case "PRICE_LEVEL_MODERATE": priceInt = 2
                    case "PRICE_LEVEL_EXPENSIVE": priceInt = 3
                    case "PRICE_LEVEL_VERY_EXPENSIVE": priceInt = 4
                    default: priceInt = 0 // Unknown
                }
            } else {
                priceInt = 0 // Unknown
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
        .filter { place in
            // 1. Strict Distance Filter
            if place.distance > radiusInKm {
                print("RestaurantService: Filtering out \(place.name) - Distance \(place.distance)km > \(radiusInKm)km")
                return false
            }
            
            // 2. Strict Price Range Filter
            // If the price is unknown (0), we now INCLUDE it per user request
            if place.priceLevel != 0 {
                if place.priceLevel < minPrice || place.priceLevel > maxPrice {
                    print("RestaurantService: Filtering out \(place.name) - Price Level \(place.priceLevel) outside \(minPrice)-\(maxPrice)")
                    return false
                }
            }
            
            // 3. Quality Filters
            let hasImages = !place.imageUrls.isEmpty
            let rating = place.rating
            
            if rawPlaces.count > 10 {
                let keep = hasImages && rating >= 3.0
                if !keep {
                    print("RestaurantService: Filtering out \(place.name) - HasImages: \(hasImages), Rating: \(rating) (Strict Quality)")
                }
                return keep
            } else {
                let keep = rating >= 2.0
                if !keep {
                    print("RestaurantService: Filtering out \(place.name) - Rating: \(rating) (Loose Quality)")
                }
                return keep
            }
        }
    }
    
    func fetchNearbyRestaurants(lat: Double, lng: Double, radius: Double, minPrice: Int, maxPrice: Int) async throws -> [GooglePlace] {
        let categories = ["restaurant", "cafe", "bakery", "bar"]
        
        print("RestaurantService: Fetching nearby with radius \(radius)m, price range \(minPrice)-\(maxPrice)")
        
        return try await withThrowingTaskGroup(of: [GooglePlace].self) { group in
            for category in categories {
                group.addTask {
                    return try await self.fetchCategory(category, lat: lat, lng: lng, radius: radius, minPrice: minPrice, maxPrice: maxPrice)
                }
            }
            
            var allPlaces: [GooglePlace] = []
            for try await categoryPlaces in group {
                allPlaces.append(contentsOf: categoryPlaces)
            }
            
            let uniquePlaces = Array(Dictionary(grouping: allPlaces, by: { $0.id }).values.compactMap { $0.first })
            print("RestaurantService: Total unique places found from API: \(uniquePlaces.count)")
            return uniquePlaces.shuffled()
        }
    }
    
    private func fetchCategory(_ type: String, lat: Double, lng: Double, radius: Double, minPrice: Int, maxPrice: Int) async throws -> [GooglePlace] {
        let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(GoogleConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.addValue("places.id,places.displayName,places.rating,places.priceLevel,places.formattedAddress,places.photos,places.location", forHTTPHeaderField: "X-Goog-FieldMask")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "includedPrimaryTypes": [type],
            "maxResultCount": 20,
            "locationRestriction": [
                "circle": [
                    "center": ["latitude": lat, "longitude": lng],
                    "radius": radius
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("RestaurantService: API Error for category \(type): Status \(httpResponse.statusCode)")
            return []
        }
        
        let decodedResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
        let rawPlaces = decodedResponse.places ?? []
        let processed = processRawPlaces(rawPlaces, userLat: lat, userLng: lng, radius: radius, minPrice: minPrice, maxPrice: maxPrice)
        print("RestaurantService: Category \(type) - Raw: \(rawPlaces.count), Processed: \(processed.count)")
        return processed
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
        if let level = place.priceLevel {
            switch level {
                case "PRICE_LEVEL_INEXPENSIVE": priceInt = 1
                case "PRICE_LEVEL_MODERATE": priceInt = 2
                case "PRICE_LEVEL_EXPENSIVE": priceInt = 3
                case "PRICE_LEVEL_VERY_EXPENSIVE": priceInt = 4
                default: priceInt = 0
            }
        } else {
            priceInt = 0
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
