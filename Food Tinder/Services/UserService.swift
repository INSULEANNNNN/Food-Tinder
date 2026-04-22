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
    func uploadProfileImage(userId: UUID, data: Data) async throws -> String
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
    
    func uploadProfileImage(userId: UUID, data: Data) async throws -> String {
        let fileName = "\(userId.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
        let path = "avatars/\(fileName)"
        
        _ = try await supabase.storage
            .from("avatars")
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )
            
        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)
            
        return publicURL.absoluteString
    }
}
