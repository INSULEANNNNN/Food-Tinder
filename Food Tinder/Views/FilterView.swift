import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SwipeViewModel
    
    @State private var distance: Double
    @State private var minPrice: Int
    @State private var maxPrice: Int
    @State private var cuisine: String
    
    init(viewModel: SwipeViewModel) {
        self.viewModel = viewModel
        _distance = State(initialValue: viewModel.radius)
        _minPrice = State(initialValue: viewModel.minPrice)
        _maxPrice = State(initialValue: viewModel.maxPrice)
        _cuisine = State(initialValue: viewModel.cuisine)
    }
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    private func priceRangeDisplay(level: Int, isMin: Bool) -> String {
        if isMin {
            switch level {
                case 1: return "฿1"
                case 2: return "฿100"
                case 3: return "฿300"
                case 4: return "฿500"
                default: return "฿1"
            }
        } else {
            switch level {
                case 1: return "฿100"
                case 2: return "฿300"
                case 3: return "฿500"
                case 4: return "฿500+"
                default: return "฿100"
            }
        }
    }
    
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
                
                Section(header: Text("งบประมาณ (Price Range)")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("ระดับราคา")
                            Spacer()
                            Text("\(priceRangeDisplay(level: minPrice, isMin: true)) - \(priceRangeDisplay(level: maxPrice, isMin: false))")
                                .fontWeight(.bold)
                                .foregroundColor(primaryColor)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("ราคาเริ่มต้น: \(priceRangeDisplay(level: minPrice, isMin: true))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Slider(value: Binding(
                                get: { Double(minPrice) },
                                set: { 
                                    minPrice = Int($0)
                                    if minPrice > maxPrice { maxPrice = minPrice }
                                }
                            ), in: 1...4, step: 1)
                            .accentColor(primaryColor)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("ราคาสูงสุด: \(priceRangeDisplay(level: maxPrice, isMin: false))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Slider(value: Binding(
                                get: { Double(maxPrice) },
                                set: { 
                                    maxPrice = Int($0)
                                    if maxPrice < minPrice { minPrice = maxPrice }
                                }
                            ), in: 1...4, step: 1)
                            .accentColor(primaryColor)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("ประเภทอาหาร / คีย์เวิร์ด")) {
                    TextField("เช่น ส้มตำ, ชาบู, พิซซ่า", text: $cuisine)
                }
                
                Section {
                    Button(action: { 
                        viewModel.applyFilters(radius: distance, minPrice: minPrice, maxPrice: maxPrice, cuisine: cuisine)
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

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView(viewModel: SwipeViewModel())
    }
}
