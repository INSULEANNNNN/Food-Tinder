import SwiftUI

struct MainView: View {
    let primaryColor = Color(red: 255/255, green: 87/255, blue: 51/255)
    
    var body: some View {
        TabView {
            SwipeView()
                .tabItem {
                    Label("Explore", systemImage: "flame.fill")
                }
            
            MatchView()
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }
            
            SessionView()
                .tabItem {
                    Label("Partner", systemImage: "person.2.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(primaryColor)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
