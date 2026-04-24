import SwiftUI
import Combine
import Supabase
import Auth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isOnboarded: Bool = false
    @Published var isLoading: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: UserProfile?
    
    var matchManager: MatchManager?
    
    private let authService = AuthService.shared
    private let userService = UserService.shared
    
    init() {
        print("AuthViewModel: Initialized")
    }
    
    func checkActiveSession() async {
        print("AuthViewModel: Checking session...")
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        do {
            let session = try await supabase.auth.session
            if !session.isExpired {
                await fetchProfile()
                Task {
                    await matchManager?.ensureActiveSession()
                    await matchManager?.fetchUserLikes()
                }
                self.isLoggedIn = true
            }
        } catch {
            print("AuthViewModel: No active session or check failed: \(error)")
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let success = try await authService.login(email: email, password: password)
            if success {
                await fetchProfile()
                Task {
                    await matchManager?.ensureActiveSession()
                    await matchManager?.fetchUserLikes()
                }
                self.isLoggedIn = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchProfile() async {
        guard let session = try? await supabase.auth.session else { return }
        let userId = session.user.id
        
        do {
            let profile = try await userService.fetchUserProfile(userId: userId)
            self.currentUser = profile
            self.isOnboarded = profile.hasOnboarded
        } catch {
            print("AuthViewModel: Fetch profile error: \(error)")
        }
    }
    
    func loginWithGoogle() async {
        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "com.phumpatananiti.Food-Tinder://login")
            )
        } catch {
            print("AuthViewModel: Google error: \(error)")
        }
    }
    
    func completeOnboarding() {
        guard var user = currentUser else { 
            self.isOnboarded = true
            return 
        }
        
        user.hasOnboarded = true
        Task {
            _ = try? await userService.updateUserProfile(user)
            await MainActor.run {
                self.currentUser = user
                withAnimation { self.isOnboarded = true }
            }
        }
    }
    
    func logout() {
        Task {
            try? await authService.logout()
            await MainActor.run {
                self.isLoggedIn = false
                self.currentUser = nil
            }
        }
    }
}
