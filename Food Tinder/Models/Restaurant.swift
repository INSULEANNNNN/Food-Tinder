import Foundation

struct GooglePlace: Identifiable {
    let id: String
    let name: String
    let rating: Double
    let priceLevel: Int // 1-4
    let distance: Double // In Kilometers
    let address: String
    let imageUrls: [String]
    
    var priceString: String {
        switch priceLevel {
            case 1: return "฿1-100"
            case 2: return "฿100-300"
            case 3: return "฿300-500"
            case 4: return "฿500+"
            default: return "ไม่ระบุ"
        }
    }
    
    var imageUrl: String {
        imageUrls.first ?? "https://via.placeholder.com/400"
    }
}
