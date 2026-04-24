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
    @Published var joinErrorMessage: String?
    
    private var cachedUserId: UUID?
    private var isFetchingLikes = false
    private let restaurantService = RestaurantService.shared
    private var realtimeChannel: RealtimeChannelV2?
    
    init() {
        print("MatchManager: Initialized")
    }
    
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
                await setupRealtimeSubscription(sessionId: existing.id)
                await fetchGroupMatches()
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
            
            await setupRealtimeSubscription(sessionId: created.id)
            self.groupMatches = []
        } catch {
            print("MatchManager: Error creating group session: \(error)")
        }
    }

    func joinSession(code: String) async -> Bool {
        self.joinErrorMessage = nil
        if cachedUserId == nil {
            cachedUserId = try? await supabase.auth.session.user.id
        }
        guard let userId = cachedUserId else { return false }
        
        do {
            let sessions: [FTSession] = try await supabase
                .from("sessions")
                .select()
                .eq("status", value: "active")
                .execute()
                .value
            
            guard let targetSession = sessions.first(where: { $0.id.uuidString.lowercased().hasPrefix(code.lowercased()) }) else {
                self.joinErrorMessage = "ไม่พบรหัสกลุ่มนี้"
                return false
            }
            
            let currentUserLoc: [UserLocation] = try await supabase
                .from("users")
                .select("id, last_latitude, last_longitude")
                .eq("id", value: userId)
                .execute()
                .value
            
            guard let myLoc = currentUserLoc.first, let myLat = myLoc.last_latitude, let myLng = myLoc.last_longitude else {
                self.joinErrorMessage = "ไม่พบข้อมูลตำแหน่งของคุณ กรุณาเปิดใช้งาน GPS"
                return false
            }
            
            let participants: [Participant] = try await supabase
                .from("session_participants")
                .select("user_id")
                .eq("session_id", value: targetSession.id)
                .execute()
                .value
            
            let participantIds = participants.map { $0.user_id.uuidString }
            
            let groupLocations: [UserLocation] = try await supabase
                .from("users")
                .select("id, last_latitude, last_longitude")
                .in("id", values: participantIds)
                .execute()
                .value
            
            for member in groupLocations {
                if let mLat = member.last_latitude, let mLng = member.last_longitude {
                    let distance = calculateDistance(lat1: myLat, lng1: myLng, lat2: mLat, lng2: mLng)
                    if distance > 3.0 {
                        self.joinErrorMessage = "กลุ่มนี้อยู่ไกลเกินไป (ต้องห่างกันไม่เกิน 3 กม.)"
                        return false
                    }
                }
            }
            
            let participant = ["session_id": targetSession.id.uuidString, "user_id": userId.uuidString]
            try await supabase.from("session_participants").insert(participant).execute()
            
            self.currentSessionId = targetSession.id
            await setupRealtimeSubscription(sessionId: targetSession.id)
            await fetchGroupMatches()
            return true
        } catch {
            print("MatchManager: Error joining session: \(error)")
            self.joinErrorMessage = "เกิดข้อผิดพลาดในการเข้าร่วมกลุ่ม"
        }
        return false
    }

    private func calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let user1 = CLLocation(latitude: lat1, longitude: lng1)
        let user2 = CLLocation(latitude: lat2, longitude: lng2)
        return user1.distance(from: user2) / 1000.0 // KM
    }

    func leaveSession() async {
        if let channel = realtimeChannel {
            await supabase.removeChannel(channel)
        }
        self.currentSessionId = nil
        self.groupMatches = []
    }
    
    private func setupRealtimeSubscription(sessionId: UUID) async {
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
            
            let likedSwipes = allSwipes.filter { $0.is_like }
            self.swipedPlaceIds = Set(allSwipes.map { $0.place_id })
            
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
            await ensureActiveSession()
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
            withAnimation {
                self.matchedRestaurants.removeAll(where: { $0.id == restaurant.id })
                self.swipedPlaceIds.remove(restaurant.id)
            }
            
            try await supabase
                .from("swipes")
                .delete()
                .eq("user_id", value: userId)
                .eq("place_id", value: restaurant.id)
                .execute()
                
            print("MatchManager: Successfully removed match \(restaurant.name)")
        } catch {
            print("MatchManager: Error removing match: \(error)")
        }
    }
}
