import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    var onRegisterSuccess: () -> Void
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @State private var showSuccessAlert = false
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        ZStack {
            // ... (rest of background)
            LinearGradient(
                gradient: Gradient(colors: [primaryColor.opacity(0.1), .white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ... (rest of header and fields)
                    VStack(spacing: 12) {
                        Text("สร้างบัญชีใหม่")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(primaryColor)
                        
                        Text("เริ่มต้นค้นหาอาหารที่คุณถูกใจ")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        CustomTextField(icon: "person.fill", placeholder: "ชื่อ-นามสกุล", text: $fullName)
                        
                        CustomTextField(icon: "envelope.fill", placeholder: "อีเมล", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        CustomSecureField(icon: "lock.fill", placeholder: "รหัสผ่าน", text: $password)
                        
                        CustomSecureField(icon: "lock.shield.fill", placeholder: "ยืนยันรหัสผ่าน", text: $confirmPassword)
                    }
                    .padding(.top, 20)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    Button(action: handleRegister) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("สมัครสมาชิก")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .shadow(color: primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty || fullName.isEmpty)
                    .padding(.top, 10)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Text("มีบัญชีอยู่แล้ว?")
                                .foregroundColor(.gray)
                            Text("เข้าสู่ระบบ")
                                .foregroundColor(primaryColor)
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 10)
                }
                .padding(30)
            }
        }
        .navigationBarHidden(true)
        .alert("สมัครสมาชิกสำเร็จ", isPresented: $showSuccessAlert) {
            Button("ตกลง") {
                dismiss()
            }
        } message: {
            Text("กรุณาตรวจสอบอีเมลของคุณเพื่อยืนยันการลงทะเบียนก่อนเข้าสู่ระบบ")
        }
    }
    
    private func handleRegister() {
        if password != confirmPassword {
            errorMessage = "รหัสผ่านไม่ตรงกัน"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Check if email is already in use
                let emailInUse = try await AuthService.shared.isEmailInUse(email: email)
                
                if emailInUse {
                    await MainActor.run {
                        errorMessage = "อีเมลนี้ถูกใช้งานแล้ว"
                        isLoading = false
                    }
                    return
                }
                
                // 2. Perform registration
                _ = try await AuthService.shared.register(email: email, name: fullName, password: password)
                
                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    RegisterView(onRegisterSuccess: {})
}
