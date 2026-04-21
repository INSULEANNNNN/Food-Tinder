import Foundation
import Supabase

struct UserProfile: Codable {
    let id: UUID
    var name: String
    var email: String
    var avatarUrl: String?
    var hasOnboarded: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case avatarUrl = "avatar_url"
        case hasOnboarded = "has_onboarded"
    }
}

protocol UserServiceProtocol {
    func fetchUserProfile(userId: UUID) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws -> Bool
}

class UserService: UserServiceProtocol {
    static let shared = UserService()
    private init() {}
    
    func fetchUserProfile(userId: UUID) async throws -> UserProfile {
        return try await supabase
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> Bool {
        try await supabase
            .from("users")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
        return true
    }
}
