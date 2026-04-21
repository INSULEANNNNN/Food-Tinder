# Food Tinder - Design Document

## 1. Overview
**Food Tinder** is a Swift-based iOS application that helps users and their friends decide where to eat by using a familiar swipe-to-like mechanic. Instead of swiping on people, users swipe on nearby restaurants sourced from the Google Places API. The app uses Supabase for a robust backend to handle user authentication, real-time matching with partners, and saving favorites.

## 2. Core Features
- **Swipe Interface:** Users are presented with a stack of restaurant cards containing photos, ratings, price levels, and distance. Users swipe right to "Like" and left to "Dislike".
- **Google Places Integration:** Fetches real-time restaurant data based on user location and search filters.
- **Filtering Options:** Users can filter their food search by:
  - Distance (e.g., within 5 miles)
  - Price ($, $$, $$$, $$$$)
  - Cuisine Type / Keywords
- **Partner Matching:** Two (or more) users can join a "session". When all participants swipe right on the same restaurant, it results in a "Match!"
- **Social Sharing:** Easily share matches and favorite restaurants with friends via standard iOS sharing menus.

## 3. Architecture & Tech Stack
- **Platform:** iOS (SwiftUI)
- **Architecture Pattern:** MVVM (Model-View-ViewModel) for clean separation of concerns.
- **Backend & Database:** **Supabase** (PostgreSQL). Used for:
  - User Authentication (Email/Password or Sign in with Apple/Google).
  - Storing user preferences and swipe history.
  - Managing live real-time "Sessions" for Partner Matching.
- **Third-Party APIs:** **Google Places API (New)** to fetch rich restaurant metadata and photos.
- **Dependency Management:** Swift Package Manager (SPM).

## 4. Database Schema (Supabase)
- `users`: User profiles (id, email, name, avatar).
- `sessions`: Active matching sessions (id, created_by, status).
- `session_participants`: Users in a specific session.
- `swipes`: User actions on places (id, session_id, user_id, place_id, is_like).
- `matches`: Resulting matches when participants both like a place.

## 5. Implementation Phases
### Phase 1: Project Setup & UI Prototype
- Initialize Xcode project with SwiftUI.
- Build the core Tinder-like swiping gesture UI (TinderCard view).
- Create basic dummy data to test the UI interactions.

### Phase 2: Supabase Integration
- Setup Supabase project.
- Integrate Supabase Swift SDK.
- Implement User Authentication (Sign up, Log in).

### Phase 3: Google Places API
- Set up GCP project and get API keys.
- Implement networking layer to fetch nearby restaurants based on filters.
- Display real Google Places data on the swipe cards.

### Phase 4: Partner Matching & Real-time Sync
- Implement Session creation and invite logic.
- Use Supabase Realtime to listen for swipes from partners.
- Implement the "Match" popup when both users like the same place.

### Phase 5: Polish & Sharing
- Implement share sheets to share matched restaurants.
- Add animations, haptics, and refined styling (Vanilla CSS/SwiftUI equivalents for modern app feel).
- App Icon and Launch Screen setup.

---

*Please review this plan. If you approve, we can begin Phase 1 by initializing the Xcode project.*