import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var avatarUrl: String?
    @State private var isLoading = false
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        Form {
            Section {
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.1))
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(primaryColor.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(fullName.prefix(1))
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(primaryColor)
                                    )
                            }
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text("เปลี่ยนรูปโปรไฟล์")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(primaryColor)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .listRowBackground(Color.clear)
            
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
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
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
                avatarUrl = user.avatarUrl
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
    
    private func saveProfile() {
        guard var user = authViewModel.currentUser else { return }
        user.name = fullName
        
        isLoading = true
        Task {
            do {
                if let data = selectedImageData {
                    let newAvatarUrl = try await UserService.shared.uploadProfileImage(userId: user.id, data: data)
                    user.avatarUrl = newAvatarUrl
                }
                
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
