import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isOnboarded: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    
    @MainActor
    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let success = try await authService.login(email: "", password: "")
            if success {
                withAnimation { isLoggedIn = true }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func logout() {
        withAnimation {
            isLoggedIn = false
            isOnboarded = false
        }
    }
    
    func completeOnboarding() {
        withAnimation {
            isOnboarded = true
        }
    }
}
