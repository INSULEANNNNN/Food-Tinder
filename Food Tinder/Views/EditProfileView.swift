import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var isLoading = false
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        Form {
            Section(header: Text("ข้อมูลส่วนตัว")) {
                HStack {
                    Text("ชื่อผู้ใช้")
                    Spacer()
                    TextField("ระบุชื่อของคุณ", text: $fullName)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("อีเมล")
                    Spacer()
                    Text(email)
                        .foregroundColor(.gray)
                }
            }
            
            Section {
                Button(action: saveProfile) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("บันทึกข้อมูล")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(primaryColor)
                    }
                }
                .disabled(isLoading || fullName.isEmpty)
            }
        }
        .navigationTitle("แก้ไขโปรไฟล์")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = authViewModel.currentUser {
                fullName = user.name
                email = user.email
            }
        }
    }
    
    private func saveProfile() {
        guard var user = authViewModel.currentUser else { return }
        user.name = fullName
        
        isLoading = true
        Task {
            do {
                let success = try await UserService.shared.updateUserProfile(user)
                if success {
                    await authViewModel.fetchProfile()
                    await MainActor.run {
                        isLoading = false
                        dismiss()
                    }
                }
            } catch {
                print("Error updating profile: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}

#Preview {
    NavigationView {
        EditProfileView()
    }
}
