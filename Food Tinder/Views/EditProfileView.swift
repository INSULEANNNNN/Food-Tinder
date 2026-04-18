import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = "ดิว eat dog"
    @State private var email = "dew@example.com"
    @State private var phoneNumber = "081-234-5678"
    @State private var birthDate = Date()
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        Form {
            Section(header: Text("ข้อมูลส่วนตัว")) {
                HStack {
                    Text("ชื่อ-นามสกุล")
                    Spacer()
                    TextField("ระบุชื่อของคุณ", text: $fullName)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("อีเมล")
                    Spacer()
                    TextField("ระบุอีเมล", text: $email)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                HStack {
                    Text("เบอร์โทรศัพท์")
                    Spacer()
                    TextField("ระบุเบอร์โทร", text: $phoneNumber)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.phonePad)
                }
                
                DatePicker("วันเกิด", selection: $birthDate, displayedComponents: .date)
            }
            
            Section(header: Text("เกี่ยวกับฉัน")) {
                TextEditor(text: .constant("สายกินที่แท้ทรู ชอบลองร้านใหม่ๆ ตลอดเวลา"))
                    .frame(height: 100)
            }
            
            Section {
                Button(action: {
                    // Logic สำหรับบันทึกข้อมูล (รอ Back-end)
                    dismiss()
                }) {
                    Text("บันทึกข้อมูล")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(primaryColor)
                }
            }
        }
        .navigationTitle("แก้ไขโปรไฟล์")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        EditProfileView()
    }
}
