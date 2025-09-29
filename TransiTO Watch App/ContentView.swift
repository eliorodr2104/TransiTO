//
//  ContentView.swift
//  TransiTO Watch App
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI

/// Contains all view app
struct ContentView: View {
    
    /// The view model for management navigation
    @EnvironmentObject var navigationViewModel: NavigationViewModel
    
    var body: some View {
        
        // Navigation stack for management the navigation
        NavigationStack(path: $navigationViewModel.path) {
            
            // Stop station list, show all stop save stop station
            StopStationsList()
                .navigationDestination(for: StopDestination.self) { destination in LineTransportListView(nameStop: destination.stopId) }
        }
    }
}

#Preview {
    ContentView()
}
