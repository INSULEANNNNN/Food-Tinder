import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isOnboarded: Bool = false
    
    func login() {
        withAnimation {
            isLoggedIn = true
        }
    }
    
    func logout() {
        withAnimation {
            isLoggedIn = false
            isOnboarded = false // Reset onboarding too if needed
        }
    }
    
    func completeOnboarding() {
        withAnimation {
            isOnboarded = true
        }
    }
}
