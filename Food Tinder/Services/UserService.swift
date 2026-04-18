import Foundation

struct UserProfile: Codable {
    let id: String
    var name: String
    var email: String
    var bio: String?
    var profileImageUrl: String?
}

protocol UserServiceProtocol {
    func fetchUserProfile(userId: String) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws -> Bool
}

class UserService: UserServiceProtocol {
    static let shared = UserService()
    private init() {}
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 500_000_000)
        return UserProfile(id: userId, name: "ดิว eat dog", email: "dew@example.com", bio: "สายกินที่แท้ทรู", profileImageUrl: nil)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> Bool {
        try await Task.sleep(nanoseconds: 800_000_000)
        // ตรงนี้ในอนาคตจะใส่: supabase.database.from("profiles").update(profile).eq("id", profile.id)
        return true
    }
}
