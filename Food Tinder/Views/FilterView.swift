import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var distance: Double = 5.0
    @State private var priceLevels: Set<Int> = [1, 2]
    @State private var cuisine: String = ""
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search Radius")) {
                    VStack {
                        HStack {
                            Text("Distance")
                            Spacer()
                            Text("\(Int(distance)) miles")
                                .foregroundColor(.gray)
                        }
                        Slider(value: $distance, in: 1...20, step: 1)
                            .accentColor(primaryColor)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Price Level")) {
                    HStack(spacing: 20) {
                        ForEach(1...4, id: \.self) { level in
                            PriceButton(level: level, isSelected: priceLevels.contains(level)) {
                                if priceLevels.contains(level) {
                                    if priceLevels.count > 1 { priceLevels.remove(level) }
                                } else {
                                    priceLevels.insert(level)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Cuisine / Keyword")) {
                    TextField("e.g. Sushi, Italian, Burgers", text: $cuisine)
                }
                
                Section {
                    Button(action: { dismiss() }) {
                        Text("Apply Filters")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(primaryColor)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
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
