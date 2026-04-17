import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name = "ดิว eat dog"
    @State private var email = "dew@example.com"
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account Profile")) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(primaryColor.opacity(0.1))
                            .frame(width: 70, height: 70)
                            .overlay(Text("🐶").font(.largeTitle))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Settings")) {
                    NavigationLink(destination: Text("Edit Profile")) {
                        Label("Edit Profile", systemImage: "person.fill")
                    }
                    NavigationLink(destination: FilterView()) {
                        Label("Food Preferences", systemImage: "slider.horizontal.3")
                    }
                }
                
                Section {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
