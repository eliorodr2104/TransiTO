//
//  SearchStopsFavorites.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 04/10/25.
//

import SwiftUI

struct SearchFavoriteStopView: View {
	
    @EnvironmentObject
	private var gtfsStaticViewModel: GTFSStaticViewModel
	
    @ObservedObject
	var favoritesViewModel: FavoritesViewModel
	
    @ObservedObject
	var navigationViewModel: NavigationViewModel
    
    @Binding
	var sheetDetent: PresentationDetent
    
    var body: some View {
        
        VStack(spacing: 20) {
            TextField(
				"Search...",
				text: self.$gtfsStaticViewModel.searchQuery
			)
			.padding(.horizontal, 20)
			.padding(.vertical, 12)
			.background(.gray.opacity(0.20), in: .capsule)
			.glassEffect()
			.padding(.top, 5)
			.autocorrectionDisabled(true)
			.textInputAutocapitalization(.none)
            
            LazyVStack {
                
				let listStops = self.gtfsStaticViewModel.searchResults
                
				ForEach(listStops, id: \.id) { stop in
                    let isFirst = stop == listStops.first
                    let isLast  = stop == listStops.last
                                        
                    if !favoritesViewModel.favoritesStops.contains(stop.stopCode) {
                        
						RowStopSearch(
                            stop: stop,
							highlight: self.gtfsStaticViewModel.searchQuery
                        ) {
                            self.favoritesViewModel.addStop(
                                to: stop.stopCode,
                                info: StopData(
                                    coordinates: Coordinates(
										latitude: stop.latitude,
										longitude: stop.longitude
									),
                                    lines: []
                                )
                            )
                            
                            // Reset data and exit
                            self.gtfsStaticViewModel.searchQuery = ""
                            self.navigationViewModel.changeStateBottomSheet(
								to: .home
							)
                            self.sheetDetent = .height(350)
                        }
                        .padding(.top, isFirst ? 15 : 0)
                        .padding(.bottom, isLast ? 15 : 0)
                        
                        if !isLast { Divider().padding(.horizontal) }
                    }
                    
                }
                
            }
            .background(.ultraThinMaterial)
            .cornerRadius(25)
            
        }
        .padding(.horizontal)
        
        
    }
}
