import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
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
                    LoginView { email, password in
                        Task {
                            await authViewModel.login(email: email, password: password)
                        }
                    }
                }
            }
            
            // Splash / Loading Overlay
            if authViewModel.isAuthenticating {
                ZStack {
                    Color.white.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("🍕")
                            .font(.system(size: 80))
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color(red: 255/255, green: 87/255, blue: 51/255))
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            print("ContentView: Appeared")
            authViewModel.matchManager = matchManager
            Task {
                await authViewModel.checkActiveSession()
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
}
