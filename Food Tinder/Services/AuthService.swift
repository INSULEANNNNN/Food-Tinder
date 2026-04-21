import Foundation
import SwiftUI
import Supabase
import Auth
import PostgREST

// โครงสร้างสำหรับเตรียมเชื่อมต่อ Supabase Auth
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> Bool
    func register(email: String, name: String, password: String) async throws -> Bool
    func logout() async throws
    func isEmailInUse(email: String) async throws -> Bool
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    private init() {}

    func isEmailInUse(email: String) async throws -> Bool {
        // Query the 'users' table as per your schema
        let count = try await supabase
            .from("users")
            .select("id", head: true, count: .exact)
            .eq("email", value: email)
            .execute()
            .count ?? 0

        return count > 0
    }

    func login(email: String, password: String) async throws -> Bool {
        try await supabase.auth.signIn(email: email, password: password)
        return true
    }

    func register(email: String, name: String, password: String) async throws -> Bool {
        // 1. Sign up with Supabase Auth including full_name in metadata
        // Your SQL trigger 'on_auth_user_created' looks for 'full_name' in raw_user_meta_data
        _ = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": AnyJSON.string(name)]
        )
        
        // Profiles are automatically created via your SQL trigger 'on_auth_user_created'
        return true
    }
    
    func logout() async throws {
        try await supabase.auth.signOut()
    }
}
