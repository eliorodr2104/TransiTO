//
//  RowFavoritesStops.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI

struct RowFavoritesStops: View {
    @EnvironmentObject private var favoritesViewModel: FavoritesViewModel
    
    var body: some View {
        
        LazyHStack(
            alignment: .firstTextBaseline,
            spacing: 5
            
        ) {
            
            ForEach(favoritesViewModel.favoritesStops, id: \.self) { stopName in
                //let coordinates = favoritesViewModel.favoriteslines[stopName]!.coordinates
                
                FavoriteStopItemView(nameStop: stopName) {
                    // TODO yet implement move map camera to coordinate
                }
            }
            
            ZStack {
                Circle()
                    .frame(width: 65, height: 65)
                    .foregroundStyle(.tint.opacity(0.2))
                
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundStyle(.tint)
                
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
    }
}
