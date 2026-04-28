import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @StateObject private var locationManager = LocationManager()
    var onComplete: () -> Void
    
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        VStack(spacing: 40) {
            // Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(index <= currentStep ? primaryColor : Color.gray.opacity(0.2))
                        .frame(height: 6)
                }
            }
            .padding(.top)
            
            // Content
            if currentStep == 0 {
                OnboardingStep(
                    emoji: "📍",
                    title: "Set Your Location",
                    description: "We'll find the best restaurants within your reach.",
                    content: AnyView(
                        Button(action: { 
                            locationManager.requestLocation()
                            nextStep() 
                        }) {
                            Label("Enable Location", systemImage: "location.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryColor)
                                .cornerRadius(12)
                        }
                    )
                )
            } else if currentStep == 1 {
                OnboardingStep(
                    emoji: "🍕",
                    title: "ประเภทอาหารที่ชอบ",
                    description: "เลือกประเภทอาหารที่คุณสนใจเป็นพิเศษ",
                    content: AnyView(
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(["อาหารไทย", "ญี่ปุ่น", "อิตาเลียน", "เบอร์เกอร์", "หมูกระทะ", "ของหวาน"], id: \.self) { item in
                                    CuisineTag(title: item, primaryColor: primaryColor)
                                }
                            }
                        }
                    )
                )
            } else {
                OnboardingStep(
                    emoji: "💰",
                    title: "งบประมาณที่คุณต้องการ",
                    description: "เลือกช่วงราคาอาหารที่คุณต้องการค้นหา",
                    content: AnyView(
                        VStack(spacing: 20) {
                            HStack {
                                Text("1 บาท")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("10,000 บาท")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Slider(value: Binding(
                                get: { pricePreference },
                                set: { pricePreference = $0 }
                            ), in: 100...10000, step: 100)
                            .accentColor(primaryColor)
                            
                            HStack {
                                Text("ราคาไม่เกิน:")
                                    .fontWeight(.medium)
                                Text("\(Int(pricePreference).formatted()) บาท")
                                    .fontWeight(.bold)
                                    .foregroundColor(primaryColor)
                                    .font(.title3)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal)
                    )
                )
            }
            
            Spacer()
            
            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("ย้อนกลับ") { currentStep -= 1 }
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(currentStep == 2 ? "เริ่มต้นใช้งาน" : "ถัดไป") {
                    if currentStep == 2 {
                        onComplete()
                    } else {
                        nextStep()
                    }
                }
                .fontWeight(.bold)
                .foregroundColor(primaryColor)
            }
        }
        .padding(30)
    }
    
    @State private var pricePreference: Double = 500.0
    
    private func nextStep() {
        withAnimation { currentStep += 1 }
    }
}

struct OnboardingStep: View {
    let emoji: String
    let title: String
    let description: String
    let content: AnyView
    
    var body: some View {
        VStack(spacing: 20) {
            Text(emoji).font(.system(size: 80))
            Text(title).font(.title.bold())
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            content
                .padding(.top, 20)
        }
    }
}

struct CuisineTag: View {
    let title: String
    let primaryColor: Color
    @State private var isSelected = false
    
    var body: some View {
        Button(action: { isSelected.toggle() }) {
            Text(title)
                .fontWeight(.medium)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSelected ? primaryColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground))
                .foregroundColor(isSelected ? primaryColor : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 1)
                )
        }
    }
}
