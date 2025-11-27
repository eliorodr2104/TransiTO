//
//  RowFavoritesStops.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI
import MapKit

struct RowFavoritesStops: View {
	
    @ObservedObject
	var favoritesViewModel: FavoritesViewModel
	
    @ObservedObject
	var locationManager: LocationManager
    
    @Binding
	var sheetDetent: PresentationDetent
    
    var addFavoriteStop: () -> Void
    
    var body: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            
            LazyHStack(
                alignment: .firstTextBaseline,
                spacing  : 10
            ) {
                
                ForEach(favoritesViewModel.favoritesStops, id: \.self) { stopName in
                    let coordinates = favoritesViewModel.favoriteslines[stopName]!.coordinates
                    
                    FavoriteStopItemView(nameStop: stopName) {
                        self.locationManager.moveCamera(
                            to: CLLocationCoordinate2D(
                                latitude: coordinates.latitude,
                                longitude: coordinates.longitude
                            )
                        )
                        
                        self.sheetDetent = .height(350)
                    }
                    
                }
                
                Button(action: {
                    self.sheetDetent = .large
                    addFavoriteStop()
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundStyle(.tint)
                }
                .frame(width: 65, height: 65)
                .background(.tint.opacity(0.2))
                .clipShape(Circle())

            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
