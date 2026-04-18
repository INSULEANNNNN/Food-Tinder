//
//  Food_TinderApp.swift
//  Food Tinder
//
//  Created by INSU on 14/4/2569 BE.
//

import SwiftUI

@main
struct Food_TinderApp: App {
    @StateObject private var matchManager = MatchManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(matchManager)
        }
    }
}
