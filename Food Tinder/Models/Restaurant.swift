import Foundation

struct GooglePlace: Identifiable {
    let id: String
    let name: String
    let rating: Double
    let priceLevel: Int // 1-4
    let distance: Double // In Kilometers
    let address: String
    let imageUrl: String
}
