import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var distance: Double = 5.0
    @State private var maxPrice: Double = 300.0
    @State private var cuisine: String = ""
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ระยะทางที่ค้นหา")) {
                    VStack {
                        HStack {
                            Text("ระยะทาง")
                            Spacer()
                            Text("\(Int(distance)) กิโลเมตร")
                                .foregroundColor(.gray)
                        }
                        Slider(value: $distance, in: 1...20, step: 1)
                            .accentColor(primaryColor)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("งบประมาณ (บาท)")) {
                    VStack {
                        HStack {
                            Text("ราคาไม่เกิน")
                            Spacer()
                            Text("\(Int(maxPrice).formatted()) บาท")
                                .fontWeight(.bold)
                                .foregroundColor(primaryColor)
                        }
                        Slider(value: $maxPrice, in: 100...10000, step: 100)
                            .accentColor(primaryColor)
                        
                        HStack {
                            Text("100")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("10,000")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("ประเภทอาหาร / คีย์เวิร์ด")) {
                    TextField("เช่น ส้มตำ, ชาบู, พิซซ่า", text: $cuisine)
                }
                
                Section {
                    Button(action: { dismiss() }) {
                        Text("ใช้ตัวกรอง")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(primaryColor)
                    }
                }
            }
            .navigationTitle("ตัวกรอง")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") { dismiss() }
                }
            }
        }
    }
}

struct PriceButton: View {
    let level: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(String(repeating: "$", count: level))
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(red: 255/255, green: 87/255, blue: 51/255) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView()
    }
}
