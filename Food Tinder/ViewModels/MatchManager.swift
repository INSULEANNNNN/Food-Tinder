import SwiftUI
import Combine
import Supabase
import Realtime
import CoreLocation

// Structs for Supabase Interaction
struct Swipe: Codable {
    let session_id: UUID
    let user_id: UUID
    let place_id: String
    let is_like: Bool
    let swiped_at: Date?
}

struct FTMatch: Codable {
    let session_id: UUID
    let place_id: String
}

struct FTSession: Codable {
    let id: UUID
    let created_by: UUID
    let status: String
    let lat: Double?
    let lng: Double?
}

struct Participant: Codable {
    let user_id: UUID
}

struct UserLocation: Codable {
    let id: UUID
    let last_latitude: Double?
    let last_longitude: Double?
}

@MainActor
class MatchManager: ObservableObject {
    @Published var matchedRestaurants: [GooglePlace] = []
    @Published var groupMatches: [GooglePlace] = []
    @Published var swipedPlaceIds: Set<String> = []
    @Published var currentSessionId: UUID?
    @Published var currentSessionStatus: String?
    @Published var joinErrorMessage: String?
    
    private var cachedUserId: UUID?
    private var isFetchingLikes = false
    private let restaurantService = RestaurantService.shared
    public let locationManager = LocationManager()
    private var realtimeChannel: RealtimeChannelV2?
    
    private let sessionKey = "com.foodtinder.currentSessionId"

    init() {
        print("MatchManager: Initialized")
        locationManager.requestLocation()
        
        // Load persisted session ID if exists
        if let savedIdString = UserDefaults.standard.string(forKey: sessionKey),
           let savedId = UUID(uuidString: savedIdString) {
            self.currentSessionId = savedId
            print("MatchManager: Found persisted session ID: \(savedId)")
        }
    }
    
    func ensureActiveSession() async {
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }
        
        // Sync location if available
        if let loc = locationManager.location {
            try? await UserService.shared.updateLocation(userId: userId, lat: loc.latitude, lng: loc.longitude)
        }
        
        // If we have a persisted session, verify it still exists and get its status
        if let sessionId = currentSessionId {
            do {
                let session: FTSession = try await supabase
                    .from("sessions")
                    .select()
                    .eq("id", value: sessionId)
                    .single()
                    .execute()
                    .value
                
                self.currentSessionStatus = session.status
                
                if session.status == "active" {
                    await setupRealtimeSubscription(sessionId: session.id)
                    await fetchGroupMatches()
                }
            } catch {
                print("MatchManager: Persisted session no longer valid: \(error)")
                self.currentSessionId = nil
                self.currentSessionStatus = nil
                UserDefaults.standard.removeObject(forKey: sessionKey)
            }
        }
        
        // If no session found/valid, we don't auto-pick any old 'active' session anymore
        // This prevents the "forced into old session" bug.
    }

    private func ensureSoloSession() async {
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }

        do {
            // Check if we already have a solo session in DB
            let sessions: [FTSession] = try await supabase
                .from("sessions")
                .select()
                .eq("created_by", value: userId)
                .eq("status", value: "solo")
                .limit(1)
                .execute()
                .value
            
            if let existing = sessions.first {
                self.currentSessionId = existing.id
                self.currentSessionStatus = "solo"
            } else {
                // Create one
                let newSession = ["created_by": userId.uuidString, "status": "solo"]
                let created: FTSession = try await supabase
                    .from("sessions")
                    .insert(newSession)
                    .select()
                    .single()
                    .execute()
                    .value
                self.currentSessionId = created.id
                self.currentSessionStatus = "solo"
            }
        } catch {
            print("MatchManager: Error ensuring solo session: \(error)")
        }
    }

    func createGroupSession() async {
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }

        // Get current location to fix as session location
        var hostLat: Double? = nil
        var hostLng: Double? = nil
        
        if let loc = locationManager.location {
            hostLat = loc.latitude
            hostLng = loc.longitude
            try? await UserService.shared.updateLocation(userId: userId, lat: loc.latitude, lng: loc.longitude)
        }

        do {
            var newSession: [String: AnyJSON] = [
                "created_by": .string(userId.uuidString),
                "status": .string("active")
            ]
            
            if let lat = hostLat, let lng = hostLng {
                newSession["lat"] = .double(lat)
                newSession["lng"] = .double(lng)
            }
            
            let created: FTSession = try await supabase
                .from("sessions")
                .insert(newSession)
                .select()
                .single()
                .execute()
                .value
            
            self.currentSessionId = created.id
            self.currentSessionStatus = "active"
            UserDefaults.standard.set(created.id.uuidString, forKey: sessionKey)
            
            let participant = ["session_id": created.id.uuidString, "user_id": userId.uuidString]
            try await supabase.from("session_participants")
                .upsert(participant, onConflict: "session_id,user_id")
                .execute()
            
            await setupRealtimeSubscription(sessionId: created.id)
            self.groupMatches = []
        } catch {
            print("MatchManager: Error creating group session: \(error)")
        }
    }

    func joinSession(code: String) async -> Bool {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        self.joinErrorMessage = nil
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return false }
        
        // Ensure location is synced before joining
        if let loc = locationManager.location {
            try? await UserService.shared.updateLocation(userId: userId, lat: loc.latitude, lng: loc.longitude)
        }
        
        do {
            print("MatchManager: Searching for session with code: \(trimmedCode)")
            try await Task.sleep(nanoseconds: 500 * 1_000_000)

            let sessions: [FTSession] = try await supabase
                .from("sessions")
                .select()
                .execute()
                .value
            
            guard let targetSession = sessions.first(where: { $0.id.uuidString.lowercased().hasPrefix(trimmedCode.lowercased()) }) else {
                self.joinErrorMessage = "ไม่พบรหัสกลุ่มนี้"
                return false
            }
            
            let participant = ["session_id": targetSession.id.uuidString, "user_id": userId.uuidString]
            try await supabase.from("session_participants")
                .upsert(participant, onConflict: "session_id,user_id")
                .execute()
            
            self.currentSessionId = targetSession.id
            self.currentSessionStatus = targetSession.status
            UserDefaults.standard.set(targetSession.id.uuidString, forKey: sessionKey)
            
            await setupRealtimeSubscription(sessionId: targetSession.id)
            await fetchGroupMatches()
            return true
        } catch {
            print("MatchManager: Error joining session: \(error)")
            self.joinErrorMessage = "เกิดข้อผิดพลาดในการเข้าร่วมกลุ่ม"
        }
        return false
    }

    func leaveSession() async {
        guard let sessionId = currentSessionId else { return }
        
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }

        do {
            // 1. Remove user from session_participants
            try await supabase
                .from("session_participants")
                .delete()
                .eq("session_id", value: sessionId)
                .eq("user_id", value: userId)
                .execute()
            
            // 2. Check remaining participants
            let remaining: [Participant] = try await supabase
                .from("session_participants")
                .select("user_id")
                .eq("session_id", value: sessionId)
                .execute()
                .value
            
            // 3. If no one left, delete the session (only if it was an active group)
            if remaining.isEmpty && currentSessionStatus == "active" {
                try? await supabase.from("swipes").delete().eq("session_id", value: sessionId).execute()
                try? await supabase.from("matches").delete().eq("session_id", value: sessionId).execute()
                try await supabase.from("sessions").delete().eq("id", value: sessionId).execute()
                print("MatchManager: Last person left. Session \(sessionId) deleted.")
            }
        } catch {
            print("MatchManager: Error leaving session: \(error)")
        }

        if let channel = realtimeChannel {
            await supabase.removeChannel(channel)
        }
        
        self.currentSessionId = nil
        self.currentSessionStatus = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
        self.groupMatches = []
        
        // After leaving a group, automatically ensure we have a solo session for personal swiping
        await ensureSoloSession()
    }
    
    private func setupRealtimeSubscription(sessionId: UUID) async {
        if let channel = realtimeChannel {
            await supabase.removeChannel(channel)
        }

        let channel = supabase.channel("session_matches_\(sessionId.uuidString)")
        
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "matches",
            filter: "session_id=eq.\(sessionId.uuidString)"
        )
        
        await channel.subscribe()
        self.realtimeChannel = channel
        
        Task {
            for await _ in changes {
                print("MatchManager: Realtime Match Detected!")
                await self.fetchGroupMatches()
            }
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
            let allSwipes: [Swipe] = try await supabase
                .from("swipes")
                .select()
                .eq("user_id", value: userId)
                .gte("swiped_at", value: dateString)
                .execute()
                .value
            
            // Filter only likes and remove duplicates by place_id
            let likedSwipes = allSwipes.filter { $0.is_like }
            var uniqueLikedPlaceIds = Set<String>()
            var uniqueLikedSwipes: [Swipe] = []
            
            for sw in likedSwipes {
                if !uniqueLikedPlaceIds.contains(sw.place_id) {
                    uniqueLikedPlaceIds.insert(sw.place_id)
                    uniqueLikedSwipes.append(sw)
                }
            }
            
            self.swipedPlaceIds = Set(allSwipes.map { $0.place_id })
            
            if uniqueLikedSwipes.isEmpty { 
                self.matchedRestaurants = []
                return 
            }
            
            var detailedPlaces: [GooglePlace] = []
            try await withThrowingTaskGroup(of: GooglePlace.self) { group in
                for sw in uniqueLikedSwipes {
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
        guard currentSessionStatus == "active" else { return }
        
        do {
            let matches: [FTMatch] = try await supabase
                .from("matches")
                .select()
                .eq("session_id", value: sessionId)
                .execute()
                .value
            
            let matchPlaceIds = matches.map { $0.place_id }
            
            if matchPlaceIds.isEmpty {
                self.groupMatches = []
                return
            }
            
            let existingIds = Set(self.groupMatches.map { $0.id })
            if Set(matchPlaceIds) == existingIds { return }
            
            var detailedPlaces: [GooglePlace] = []
            try await withThrowingTaskGroup(of: GooglePlace.self) { group in
                for pid in matchPlaceIds {
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
        if isLike {
            self.swipedPlaceIds.insert(placeId)
        }
        
        if currentSessionId == nil {
            await ensureSoloSession()
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
            swiped_at: Date()
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
    
    func removeMatch(_ restaurant: GooglePlace) async {
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return }
        
        do {
            // Update UI immediately
            withAnimation {
                self.matchedRestaurants.removeAll(where: { $0.id == restaurant.id })
                self.swipedPlaceIds.remove(restaurant.id)
            }
            
            print("MatchManager: Deleting match for \(restaurant.name) from DB...")
            
            // 1. Delete from swipes (Personal Like)
            try await supabase
                .from("swipes")
                .delete()
                .eq("user_id", value: userId)
                .eq("place_id", value: restaurant.id)
                .execute()
            
            // 2. Delete from matches (Group Matches)
            // This ensures it also disappears from group lists if you un-liked it
            try await supabase
                .from("matches")
                .delete()
                .eq("place_id", value: restaurant.id)
                .execute()
                
            print("MatchManager: Successfully removed match \(restaurant.name) from all tables.")
        } catch {
            print("MatchManager: Error removing match: \(error)")
        }
    }
}
