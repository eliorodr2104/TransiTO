//
//  StopStationHome.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI

struct DepartureRowView: View {
        
	var arrival    : Arrival
    let stopCode   : String
    let typeVehicle: TypeVehicle
    let onClick    : (_ direction: String?) -> Void
    
    var body: some View {

        VStack(
			alignment: .leading,
			spacing  : 10
		) {
            
            HStack(
				alignment: .firstTextBaseline,
				spacing  : 7
			) {
				Image(systemName: typeVehicle.icon)
					.font(.headline)
					.foregroundStyle(.primary)
					.padding(10)
					.background {
						Circle()
							.fill(.tint)
							.stroke(
								.ultraThickMaterial,
								lineWidth: 3
							)
					}
                
                Text("Linea \(arrival.line)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Divider()
            
            HStack {
				Text(arrival.direction.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
				Text("\(arrival.remainingMinutes) min")
					.font(.subheadline)
					.fontDesign(.monospaced)
					.foregroundStyle(
						arrival.remainingMinutes <= 5 ? .red :
						arrival.remainingMinutes <= 10 && arrival.remainingMinutes > 5 ? .yellow :
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
