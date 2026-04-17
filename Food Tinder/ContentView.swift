import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                if authViewModel.isOnboarded {
                    MainView()
                } else {
                    OnboardingView {
                        authViewModel.completeOnboarding()
                    }
                }
            } else {
                LoginView {
                    authViewModel.login()
                }
            }
        }
        .environmentObject(authViewModel) // ส่งสถานะไปให้หน้าอื่นใช้ได้
    }
}

#Preview {
    ContentView()
}
