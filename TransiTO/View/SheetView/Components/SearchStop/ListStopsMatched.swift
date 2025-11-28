//
//  ListStopsMatched.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI
import CoreLocation

struct ListStopsMatched: View {
    @EnvironmentObject
	private var gtfsStatic: GTFSStaticViewModel
	
    @ObservedObject
	var navigationViewModel: NavigationViewModel
	
    @ObservedObject
	var locationManager: LocationManager
    
    var closeSearch: () -> Void
    
    var body: some View {
        
        LazyVStack(
            alignment: .leading
        ) {
			let listStops = self.gtfsStatic.searchResults
            
			ForEach(listStops, id: \.id) { stop in
                let isFirst = stop == listStops.first
                let isLast  = stop == listStops.last
                
                RowStopSearch(
					stop: stop,
					highlight: gtfsStatic.searchQuery
				) {
                    self.locationManager.moveCamera(
						to: CLLocationCoordinate2D(
							latitude : stop.latitude,
							longitude: stop.longitude
						)
					)
                    
                    self.navigationViewModel.changeStopFocus(to: stop)
                    closeSearch()
                    
                }
                .padding(.top, isFirst ? 15 : 0)
                .padding(.bottom, isLast ? 15 : 0)
                
                if !isLast { Divider().padding(.horizontal) }
            }

        }
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .padding()
    }
}
