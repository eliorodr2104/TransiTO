//
//  TransiTOApp.swift
//  TransiTO Watch App
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI

@main
struct TransiTO_Watch_AppApp: App {
    
    /// The view model save the favorites routes and stops station
    @StateObject var storageFavorite     = StorageFavoriteViewmodel()
    
    /// The view model get the next arrival for single stop station
    @StateObject var arrivalsViewModel   = ArrivalsViewmodel()
    
    /// The view model manage the navigation to widget and principal app
    @StateObject var navigationViewModel = NavigationViewModel()
    
    /// The view model get information for all transport station
    @StateObject var transportStops      = TransportStopsViewModel()

    var body: some Scene {
    
        WindowGroup {
            
            // Content view app
            ContentView()
                .environmentObject(storageFavorite)
                .environmentObject(arrivalsViewModel)
                .environmentObject(navigationViewModel)
                .environmentObject(transportStops)
                .onOpenURL { url in handleDeepLink(url: url) } // If the url is open then execute navigation
            
        }
    }
    
    /// Get url and set navigation
    private func handleDeepLink(url: URL) {
        
        // If the url is app url continue app
        guard url.scheme == "transito" else { return }
        
        // Get url components
        let components = url.pathComponents
        
        // transito://stop/40 -> pathComponents: ["/", "40"]
        // Navigation to bus stop information
        if components.count >= 2 { navigationViewModel.navigateTo(stopId: components[1]) }
    }
}
