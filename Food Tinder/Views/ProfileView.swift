import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("ข้อมูลบัญชี")) {
                    HStack(spacing: 16) {
                        if let avatarUrl = authViewModel.currentUser?.avatarUrl, let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle().fill(primaryColor.opacity(0.1))
                            }
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(primaryColor.opacity(0.1))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Text(authViewModel.currentUser?.name.prefix(1) ?? "👤")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(primaryColor)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.name ?? "กำลังโหลด...")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("การตั้งค่า")) {
                    NavigationLink(destination: EditProfileView()) {
                        Label("แก้ไขโปรไฟล์", systemImage: "person.fill")
                    }
                    // FilterView will be managed from SwipeView instead, or we need to pass a VM
                }
                
                Section {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        HStack {
                            Spacer()
                            Text("ออกจากระบบ")
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("โปรไฟล์")
            .task {
                await authViewModel.fetchProfile()
            }
        }
    }
}
