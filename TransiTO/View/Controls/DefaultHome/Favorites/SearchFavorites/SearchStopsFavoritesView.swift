//
//  SearchStopsFavorites.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 04/10/25.
//

import SwiftUI

struct SearchStopsFavoritesView: View {
    @EnvironmentObject private var stopsViewModel     : GTFSStaticViewModel
    @EnvironmentObject private var favoritesViewModel : FavoritesViewModel
    @EnvironmentObject private var navigationViewModel: NavigationViewModel
    
    @Binding var sheetDetent: PresentationDetent
    
    var body: some View {
        
        VStack(spacing: 20) {
            TextField("Search...", text: $stopsViewModel.searchQuery)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.gray.opacity(0.20), in: .capsule)
                .glassEffect()
                .padding(.top, 5)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.none)
            
            LazyVStack {
                
                let listStops = stopsViewModel.searchResults
                
                ForEach(listStops) { stop in
                    let isFirst = stop == listStops.first
                    let isLast  = stop == listStops.last
                    
                    RowStopSearch(stop: stop, highlight: stopsViewModel.searchQuery) {
                        self.favoritesViewModel.addStop(
                            to: stop.stopCode,
                            info: InfoStop(
                                coordinates: Coordinates(latitude: stop.latitude, longitude: stop.longitude),
                                lines: [],
                            )
                        )
                        
                        // Reset data and exit
                        self.stopsViewModel.searchQuery = ""
                        self.navigationViewModel.changeStateBottomSheet(to: .EMPTY_HOME)
                        self.sheetDetent = .height(350)
                        
                    }
                    .padding(.top, isFirst ? 15 : 0)
                    .padding(.bottom, isLast ? 15 : 0)
                    
                    if !isLast { Divider().padding(.horizontal) }
                }
                
            }
            .background(.ultraThinMaterial)
            .cornerRadius(25)
            
        }
        .padding(.horizontal)
        
        
    }
}
