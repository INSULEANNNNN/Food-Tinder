import SwiftUI

struct SwipeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text("Swipe")
                    .font(.title.bold())
                Text("This is a placeholder for the Swipe experience.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationTitle("Swipe")
        }
    }
}

#Preview {
    SwipeView()
}
