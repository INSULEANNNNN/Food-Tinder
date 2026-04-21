import SwiftUI
import Supabase
import Auth

// Configuration for Supabase
struct SupabaseConfig {
    static let url = URL(string: "https://sdazemrcsurzvfwkqxsh.supabase.co/")!
    static let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkYXplbXJjc3VyenZmd2txeHNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTY2OTcsImV4cCI6MjA5MTczMjY5N30.X6ttvR9B67CH5RsQ5_FMg4reN-ZC_YetEmV77ieLnoM"
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.key,
    options: .init(
        auth: .init(
            emitLocalSessionAsInitialSession: true
        )
    )
)

@main
struct Food_TinderApp: App {
    @StateObject private var matchManager = MatchManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(matchManager)
                .onOpenURL { url in
                    Task {
                        try? await supabase.auth.session(from: url)
                    }
                }
        }
    }
}
