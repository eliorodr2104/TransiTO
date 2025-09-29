//
//  BottomStopStationView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI

struct StopStationRow: View {
    
    /// The view model get next arrivals
    @EnvironmentObject var arrivalsViewModel: ArrivalsViewmodel
    
    /// The view model get stops and line saved
    @EnvironmentObject var storageFavorite  : StorageFavoriteViewmodel
    
    /// The view model get all information for stop stations
    @EnvironmentObject var transportStops   : TransportStopsViewModel
    
    /// State var contains lines available
    let linesAvailable: Int
    
    let nameStop: String
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "mappin")
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                
                let name = (transportStops.getBusStop(byCode: nameStop)?.stopName ?? "Nil").localizedCapitalized
                Text(name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
            }
                        
            Text("\(linesAvailable) available")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
        }
        .padding(.vertical, 8)
        
    }
}
