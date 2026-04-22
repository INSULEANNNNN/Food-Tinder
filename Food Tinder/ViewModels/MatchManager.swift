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

struct Participant: Codable {
    let user_id: UUID
}

@MainActor
class MatchManager: ObservableObject {
    @Published var matchedRestaurants: [GooglePlace] = []
    @Published var groupMatches: [GooglePlace] = []
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
                .eq("status", value: "active")
                .limit(1)
                .execute()
                .value
            
            if let existing = sessions.first {
                self.currentSessionId = existing.id
                await fetchGroupMatches()
            } else {
                // If no session, we'll create a default one when they swipe or they can create a group
            }
        } catch {
            print("MatchManager: Error ensuring session: \(error)")
        }
    }

    func createGroupSession() async {
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }

        do {
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
            try await supabase.from("session_participants").insert(participant).execute()
            
            self.groupMatches = []
        } catch {
            print("MatchManager: Error creating group session: \(error)")
        }
    }

    func joinSession(code: String) async -> Bool {
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return false }
        
        // In this simple version, we use the first 8 chars of UUID as code
        // We search for a session where the ID starts with the code
        do {
            let sessions: [FTSession] = try await supabase
                .from("sessions")
                .select()
                .eq("status", value: "active")
                .execute()
                .value
            
            if let targetSession = sessions.first(where: { $0.id.uuidString.lowercased().hasPrefix(code.lowercased()) }) {
                let participant = ["session_id": targetSession.id.uuidString, "user_id": userId.uuidString]
                try await supabase.from("session_participants").insert(participant).execute()
                
                self.currentSessionId = targetSession.id
                await fetchGroupMatches()
                return true
            }
        } catch {
            print("MatchManager: Error joining session: \(error)")
        }
        return false
    }

    func leaveSession() async {
        self.currentSessionId = nil
        self.groupMatches = []
        // Optional: delete from participants or just clear local state
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
    
    func fetchGroupMatches() async {
        guard let sessionId = currentSessionId else { return }
        
        do {
            // 1. Get all participants in this session
            let participants: [Participant] = try await supabase
                .from("session_participants")
                .select("user_id")
                .eq("session_id", value: sessionId)
                .execute()
                .value
            
            let participantCount = participants.count
            if participantCount < 2 { 
                self.groupMatches = []
                return 
            }
            
            // 2. Get all LIKES in this session
            let swipes: [Swipe] = try await supabase
                .from("swipes")
                .select()
                .eq("session_id", value: sessionId)
                .eq("is_like", value: true)
                .execute()
                .value
            
            // 3. Find place_ids liked by ALL participants
            let groupedByPlace = Dictionary(grouping: swipes, by: { $0.place_id })
            let commonPlaceIds = groupedByPlace.filter { $0.value.count >= participantCount }.map { $0.key }
            
            if commonPlaceIds.isEmpty {
                self.groupMatches = []
                return
            }
            
            // 4. Fetch details
            var detailedPlaces: [GooglePlace] = []
            try await withThrowingTaskGroup(of: GooglePlace.self) { group in
                for pid in commonPlaceIds {
                    group.addTask {
                        return try await self.restaurantService.fetchRestaurantDetails(placeId: pid)
                    }
                }
                for try await place in group {
                    detailedPlaces.append(place)
                }
            }
            
            self.groupMatches = detailedPlaces
        } catch {
            print("MatchManager: Error fetching group matches: \(error)")
        }
    }
    
    func recordSwipe(placeId: String, isLike: Bool) async {
        // Only update local filter if it's a LIKE
        if isLike {
            self.swipedPlaceIds.insert(placeId)
        }
        
        if currentSessionId == nil {
            await ensureActiveSession()
            // If still nil, create one
            if currentSessionId == nil {
                await createGroupSession()
            }
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
            swiped_at: Date() // Set current date for reset logic
        )
        
        do {
            try await supabase
                .from("swipes")
                .upsert(swipe, onConflict: "session_id,user_id,place_id")
                .execute()
            
            if isLike {
                await fetchGroupMatches()
            }
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
    
    func removeMatch(_ restaurant: GooglePlace) async {
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }
        
        do {
            // 1. Remove from local lists first for responsive UI
            withAnimation {
                self.matchedRestaurants.removeAll(where: { $0.id == restaurant.id })
                self.swipedPlaceIds.remove(restaurant.id)
            }
            
            // 2. Delete from Supabase - remove by user_id and place_id to catch it 
            // even if it was recorded in a different session
            try await supabase
                .from("swipes")
                .delete()
                .eq("user_id", value: userId)
                .eq("place_id", value: restaurant.id)
                .execute()
                
            // 3. Update group matches if necessary
            if currentSessionId != nil {
                await fetchGroupMatches()
            }
                
            print("MatchManager: Successfully removed match \(restaurant.name)")
        } catch {
            print("MatchManager: Error removing match: \(error)")
        }
    }
}
