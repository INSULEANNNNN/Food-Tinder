import SwiftUI

struct SessionView: View {
    @EnvironmentObject var matchManager: MatchManager
    @State private var showingCreateAlert = false
    @State private var sessionCode = ""
    @State private var showingJoinSheet = false
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let sessionId = matchManager.currentSessionId {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 80))
                            .foregroundColor(primaryColor)
                        
                        Text("กำลังอยู่ในเซสชันกลุ่ม")
                            .font(.title2.bold())
                        
                        Text("รหัสเซสชัน: \(sessionId.uuidString.prefix(8))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("แมตช์ของกลุ่ม")
                                .font(.headline)
                            
                            if matchManager.groupMatches.isEmpty {
                                Text("ยังไม่มีร้านที่ทุกคนถูกใจตรงกัน")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(matchManager.groupMatches) { restaurant in
                                            VStack {
                                                AsyncImage(url: URL(string: restaurant.imageUrl)) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Color.gray.opacity(0.1)
                                                }
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                
                                                Text(restaurant.name)
                                                    .font(.caption.bold())
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 100)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding()
                        
                        Button(action: {
                            Task {
                                await matchManager.leaveSession()
                            }
                        }) {
                            Text("ออกจากกลุ่ม")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 30) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.gray.opacity(0.2))
                        
                        VStack(spacing: 8) {
                            Text("ปัดร่วมกับเพื่อน")
                                .font(.title.bold())
                            Text("สร้างกลุ่มเพื่อหาร้านอาหารที่ทุกคนชอบตรงกัน")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    await matchManager.createGroupSession()
                                }
                            }) {
                                Text("สร้างกลุ่มใหม่")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(primaryColor)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingJoinSheet = true
                            }) {
                                Text("เข้าร่วมกลุ่มด้วยรหัส")
                                    .fontWeight(.bold)
                                    .foregroundColor(primaryColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(primaryColor.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Partner Matching")
            .sheet(isPresented: $showingJoinSheet) {
                JoinSessionView()
            }
        }
    }
}

struct JoinSessionView: View {
    @EnvironmentObject var matchManager: MatchManager
    @Environment(\.dismiss) var dismiss
    @State private var code = ""
    @State private var isLoading = false
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("ระบุรหัสเซสชัน")
                    .font(.headline)
                
                TextField("เช่น 1234abcd", text: $code)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocapitalization(.none)
                
                if let error = matchManager.joinErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: { 
                    join() 
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("เข้าร่วม")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(primaryColor)
                            .cornerRadius(12)
                    }
                }
                .disabled(code.isEmpty || isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("เข้าร่วมกลุ่ม")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") { dismiss() }
                }
            }
        }
    }
    
    private func join() {
        isLoading = true
        Task {
            let success = await matchManager.joinSession(code: code)
            if success {
                dismiss()
            }
            isLoading = false
        }
    }
}
