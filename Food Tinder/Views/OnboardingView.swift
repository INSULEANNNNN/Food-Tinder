import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
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
                        Button(action: { nextStep() }) {
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
                    title: "Favorite Cuisines",
                    description: "Select what you're usually in the mood for.",
                    content: AnyView(
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(["Italian", "Sushi", "Burgers", "Thai", "Mexican", "Desserts"], id: \.self) { item in
                                    CuisineTag(title: item)
                                }
                            }
                        }
                    )
                )
            } else {
                OnboardingStep(
                    emoji: "💰",
                    title: "Price Preference",
                    description: "How much do you usually want to spend?",
                    content: AnyView(
                        HStack(spacing: 20) {
                            ForEach(1...4, id: \.self) { level in
                                Text(String(repeating: "$", count: level))
                                    .fontWeight(.bold)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    )
                )
            }
            
            Spacer()
            
            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") { currentStep -= 1 }
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(currentStep == 2 ? "Get Started" : "Next") {
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
    @State private var isSelected = false
    
    var body: some View {
        Button(action: { isSelected.toggle() }) {
            Text(title)
                .fontWeight(.medium)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color(red: 255/255, green: 87/255, blue: 51/255).opacity(0.1) : Color.gray.opacity(0.05))
                .foregroundColor(isSelected ? Color(red: 255/255, green: 87/255, blue: 51/255) : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color(red: 255/255, green: 87/255, blue: 51/255) : Color.clear, lineWidth: 1)
                )
        }
    }
}
