//
//  TransiTOApp.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI

@main
struct TransiTO_iOSApp: App {
    @StateObject private var locationManager         = LocationManager()
    @StateObject private var navigationViewModel     = NavigationViewModel()
    @StateObject private var favoritesStopsViewModel = FavoritesViewModel()

    @StateObject private var gtfsStaticViewModel     = GTFSStaticViewModel()
    @StateObject private var arrivalsViewModel       = ArrivalsViewmodel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(arrivalsViewModel)
                .environmentObject(gtfsStaticViewModel)
                .environmentObject(locationManager)
                .environmentObject(navigationViewModel)
                .environmentObject(favoritesStopsViewModel)
        }
    }
}
