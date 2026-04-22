import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SwipeViewModel
    
    @State private var distance: Double
    @State private var maxPrice: Int
    @State private var cuisine: String = ""
    
    init(viewModel: SwipeViewModel) {
        self.viewModel = viewModel
        _distance = State(initialValue: viewModel.radius)
        _maxPrice = State(initialValue: viewModel.maxPrice)
    }
    
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
                
                Section(header: Text("งบประมาณ (Price Level)")) {
                    VStack {
                        HStack {
                            Text("ระดับราคา")
                            Spacer()
                            Text(String(repeating: "฿", count: maxPrice))
                                .fontWeight(.bold)
                                .foregroundColor(primaryColor)
                        }
                        Slider(value: Binding(
                            get: { Double(maxPrice) },
                            set: { maxPrice = Int($0) }
                        ), in: 1...4, step: 1)
                        .accentColor(primaryColor)
                        
                        HStack {
                            Text("ประหยัด")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("หรูหรา")
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
                    Button(action: { 
                        viewModel.applyFilters(radius: distance, maxPrice: maxPrice)
                        dismiss() 
                    }) {
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
        FilterView(viewModel: SwipeViewModel())
    }
}
