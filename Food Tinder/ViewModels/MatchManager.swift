import SwiftUI
import Combine
import Supabase
import Realtime

// Structs for Supabase Interaction
struct Swipe: Codable {
    let session_id: UUID
    let user_id: UUID
    let place_id: String
    let is_like: Bool
    let swiped_at: Date?
}

struct FTSession: Codable {
    let id: UUID
    let created_by: UUID
    let status: String
}

@MainActor
class MatchManager: ObservableObject {
    @Published var matchedRestaurants: [GooglePlace] = []
    @Published var swipedPlaceIds: Set<String> = []
    @Published var currentSessionId: UUID?
    
    private var cachedUserId: UUID?
    private var isFetchingLikes = false
    private let restaurantService = RestaurantService.shared
    
    init() {
        print("MatchManager: Initialized")
    }
    
    // Ensure the user has a session to save their swipes in
    func ensureActiveSession() async {
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }
        
        do {
            let sessions: [FTSession] = try await supabase
                .from("sessions")
                .select()
                .eq("created_by", value: userId)
                .limit(1)
                .execute()
                .value
            
            if let existing = sessions.first {
                self.currentSessionId = existing.id
            } else {
                let newSession = ["created_by": userId.uuidString, "status": "active"]
                let created: FTSession = try await supabase
                    .from("sessions")
                    .insert(newSession)
                    .select()
                    .single()
                    .execute()
                    .value
                self.currentSessionId = created.id
                
                let participant = ["session_id": created.id.uuidString, "user_id": userId.uuidString]
                try? await supabase.from("session_participants").insert(participant).execute()
            }
        } catch {
            print("MatchManager: Error ensuring session: \(error)")
        }
    }
    
    func fetchUserLikes() async {
        guard !isFetchingLikes else { return }
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }
        
        isFetchingLikes = true
        defer { isFetchingLikes = false }
        
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dateString = formatter.string(from: sevenDaysAgo)
        
        do {
            // 1. Fetch ALL swipes from the last 7 days
            let allSwipes: [Swipe] = try await supabase
                .from("swipes")
                .select()
                .eq("user_id", value: userId)
                .gte("swiped_at", value: dateString)
                .execute()
                .value
            
            // 2. Remember only LIKED IDs to filter them out of the stack
            let likedSwipes = allSwipes.filter { $0.is_like }
            self.swipedPlaceIds = Set(likedSwipes.map { $0.place_id })
            
            print("MatchManager: Restoring \(likedSwipes.count) likes")
            
            if likedSwipes.isEmpty { 
                self.matchedRestaurants = []
                return 
            }
            
            var detailedPlaces: [GooglePlace] = []
            try await withThrowingTaskGroup(of: GooglePlace.self) { group in
                for sw in likedSwipes {
                    group.addTask {
                        return try await self.restaurantService.fetchRestaurantDetails(placeId: sw.place_id)
                    }
                }
                for try await place in group {
                    detailedPlaces.append(place)
                }
            }
            
            self.matchedRestaurants = detailedPlaces
        } catch {
            print("MatchManager: Error restoring matches: \(error)")
        }
    }
    
    func recordSwipe(placeId: String, isLike: Bool) async {
        // Only update local filter if it's a LIKE
        if isLike {
            self.swipedPlaceIds.insert(placeId)
        }
        
        guard let sessionId = currentSessionId else { return }
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }
        
        let swipe = Swipe(
            session_id: sessionId,
            user_id: userId,
            place_id: placeId,
            is_like: isLike,
            swiped_at: nil
        )
        
        do {
            try await supabase
                .from("swipes")
                .upsert(swipe, onConflict: "session_id,user_id,place_id")
                .execute()
        } catch {
            print("MatchManager: Error saving swipe: \(error)")
        }
    }
    
    func addMatch(_ restaurant: GooglePlace) {
        if !self.matchedRestaurants.contains(where: { $0.id == restaurant.id }) {
            withAnimation {
                self.matchedRestaurants.insert(restaurant, at: 0)
            }
        }
    }
}
