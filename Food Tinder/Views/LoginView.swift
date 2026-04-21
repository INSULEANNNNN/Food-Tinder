import SwiftUI
import Supabase
import Auth

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var onLoginSuccess: (String, String) -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAppleAlert = false
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [primaryColor.opacity(0.1), .white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Text("🍕")
                            .font(.system(size: 80))
                        
                        Text("Food Tinder")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(primaryColor)
                        
                        Text("Swipe. Match. Eat.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .fontWeight(.medium)
                    }
                    .padding(.bottom, 30)
                    
                    VStack(spacing: 16) {
                        CustomTextField(icon: "envelope.fill", placeholder: "อีเมล", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        CustomSecureField(icon: "lock.fill", placeholder: "รหัสผ่าน", text: $password)
                    }
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: handleLogin) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("เข้าสู่ระบบ")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(primaryColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                    .shadow(color: primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                        
                        NavigationLink(destination: RegisterView(onRegisterSuccess: {
                            onLoginSuccess(email, password)
                        })) {
                            HStack {
                                Text("ยังไม่มีบัญชี?")
                                    .foregroundColor(.gray)
                                Text("สมัครสมาชิก")
                                    .foregroundColor(primaryColor)
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    VStack(spacing: 20) {
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
                            Text("หรือเข้าใช้ด้วย").font(.caption2).foregroundColor(.gray).padding(.horizontal, 8)
                            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
                        }
                        
                        HStack(spacing: 20) {
                            SocialButton(icon: "applelogo", title: "Apple", color: .black) {
                                showAppleAlert = true
                            }
                            
                            SocialButton(icon: "g.circle.fill", title: "Google", color: .white, textColor: .black) {
                                Task {
                                    await authViewModel.loginWithGoogle()
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding(30)
            }
        }
        .alert("Coming soon!", isPresented: $showAppleAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Coming soon when we have enough money!")
        }
    }
    
    private func handleLogin() {
        Task {
            await authViewModel.login(email: email, password: password)
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SocialButton: View {
    let icon: String
    let title: String
    let color: Color
    var textColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color == .white ? Color.gray.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
    }
}
