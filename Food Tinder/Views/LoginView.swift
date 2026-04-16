import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingSignUp = false
    
    // Theme Colors
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255) // Food-inspired Orange/Red
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [primaryColor.opacity(0.1), .white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo & Header
                VStack(spacing: 12) {
                    Text("🍕")
                        .font(.system(size: 80))
                    
                    Text("Food Tinder")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(primaryColor)
                    
                    Text("Swipe Match Eat")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                }
                .padding(.bottom, 30)
                
                // Input Fields
                VStack(spacing: 16) {
                    CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    CustomSecureField(icon: "lock.fill", placeholder: "Password", text: $password)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: handleAuthAction) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isShowingSignUp ? "Create Account" : "Sign In")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .shadow(color: primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    
                    Button(action: {
                        withAnimation {
                            isShowingSignUp.toggle()
                            errorMessage = nil
                        }
                    }) {
                        Text(isShowingSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(primaryColor)
                            .fontWeight(.semibold)
                    }
                }
                
                // Social Login Section
                VStack(spacing: 20) {
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
                        Text("OR").font(.caption2).foregroundColor(.gray).padding(.horizontal, 8)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
                    }
                    
                    HStack(spacing: 20) {
                        SocialButton(icon: "applelogo", title: "Apple", color: .black) {
                            print("Apple Login Clicked")
                        }
                        
                        SocialButton(icon: "g.circle.fill", title: "Google", color: .white, textColor: .black) {
                            print("Google Login Clicked")
                        }
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(30)
        }
    }
    
    // จำลองการทำงาน (Mock Action)
    private func handleAuthAction() {
        isLoading = true
        errorMessage = nil
        
        // จำลองการโหลด 1 วินาที
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            print("\(isShowingSignUp ? "Sign Up" : "Sign In") with: \(email)")
            
            // ลองโชว์ Error สมมติถ้าเป็นรหัสผิด
            if password == "1234" {
                errorMessage = "Invalid password. Please try again."
            }
        }
    }
}

// MARK: - Subviews สำหรับตกแต่ง UI

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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
