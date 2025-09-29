//
//  TransportStationList.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI

/// Rappresent all transport station saving
struct StopStationsList: View {
    
    /// The view model get next arrival for single stop
    @EnvironmentObject var arrivalsViewModel: ArrivalsViewmodel
    
    /// The view model get storage the favorite stops and lines
    @EnvironmentObject var storageFavorite  : StorageFavoriteViewmodel
    
    /// The view model get transport stops information
    @EnvironmentObject var transportStops   : TransportStopsViewModel
    
    @State private var isRefreshingAvailable: Bool = false
    @State private var fetchTask: Task<Void, Never>? = nil
            
    var body: some View {
        
        // Contains Body
        ZStack {
            listFavorites
            
            if storageFavorite.stopStations.isEmpty {
                
                Text("Favorite stops is empty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
            }
            
            if isRefreshingAvailable {
                ProgressView()
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { addFavoriteButton } } // Button for add new stop station favorite
        
    }
    
    /// List with show all stop stations row
    private var listFavorites: some View {
        
        List(storageFavorite.stopStations, id: \.self) { nameStop in
            
            if !storageFavorite.stopStations.isEmpty && !isRefreshingAvailable{
                
                let lines = storageFavorite.getLines(to: nameStop)
                let available = arrivalsViewModel.getAvailableLines(for: nameStop, in: lines)
                
                NavigationLink(destination: LineTransportListView(nameStop: nameStop)) {
                    
                    // Row stop station
                    StopStationRow(linesAvailable: available, nameStop: nameStop)
                }
                .swipeActions {
                    
                    // Remove Row
                    Button(role: .destructive) {
                        withAnimation { storageFavorite.removeStop(from: nameStop) }
                        
                    } label: { Label("Remove", systemImage: "trash") }
                }
            }
            
        }
        .onAppear {
            
            if !storageFavorite.stopStations.isEmpty {
                fetchTask = Task {
                    await self.arrivalsViewModel.fetchFavoriteStopArrivals(
                        favoritesStops: self.storageFavorite.stopStations,
                        updateAvailable: self.$isRefreshingAvailable
                    )
                    
                    self.isRefreshingAvailable = false
                }
            }
        }
        .onDisappear {
            fetchTask?.cancel()
            fetchTask = nil
            
        }
        .listStyle(.carousel)

    }
    
    /// Button in toolbar for add favorite station
    private var addFavoriteButton: some View {
        NavigationLink(destination: AddFavoriteStation()) {
            Label("Add", systemImage: "plus")
                .labelStyle(.iconOnly)
            
        }
        .accessibilityLabel("Add favorite station")
    }
    
}
