//
//  StopStationHome.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI

struct LineRowStateView: View {
    
	var remainingArrivalTime: (
		_ nameStop: String,
		_ line	  : String
	) -> Int?
    
    // Attributes struct
    let arrival    : Arrival
    let stopCode   : String
    let typeVehicle: Int
    let onClick    : (_ direction: String?) -> Void
    
    var body: some View {

        VStack(alignment: .leading, spacing: 10) {
            
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                ZStack {
                    Circle()
                        .fill(.tint)
                        .frame(width: 35, height: 35)
                    
                    Image(systemName: typeVehicle == 0 ? "tram.fill" : typeVehicle == 3 ? "bus.fill" : "m.square.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                }
                
                Text(arrival.line)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Divider()
            
            HStack {
                Text(arrival.direction)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                let timeRemaining = self.remainingArrivalTime(
					stopCode,
					arrival.line
				) ?? 0
				
                Text("\(timeRemaining) min")
                    .font(.subheadline)
                    .foregroundStyle(
						timeRemaining <= 5 ? .red :
						timeRemaining <= 10 && timeRemaining > 5 ? .yellow :
						.secondary
					)
            }
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .padding(.horizontal)
        .onTapGesture { onClick(arrival.direction) }
        
    }
}
