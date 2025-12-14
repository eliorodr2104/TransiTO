//
//  StopStationHome.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI

struct DepartureRowView: View {
    
    // Get current color scheme from devices
    @Environment(\.colorScheme)
    var colorScheme
        
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
                Image(systemName: self.typeVehicle.icon)
					.font(.headline)
					.foregroundStyle(
                        self.colorScheme == .dark ? .black : .white
                    )
					.padding(10)
					.background {
						Circle()
							.fill(.tint)
							.stroke(
								.ultraThickMaterial,
								lineWidth: 3
							)
					}
                
                Text("Linea \(self.arrival.line)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Divider()
            
            HStack {
                Text(self.arrival.direction.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(self.arrival.remainingMinutes) min")
					.font(.subheadline)
                    .fontDesign(.rounded)
					// .fontDesign(.monospaced) -> Not pretty font
                    .foregroundStyle(.secondary)
//					.foregroundStyle(
//						arrival.remainingMinutes <= 5 ? .red :
//						arrival.remainingMinutes <= 10 && arrival.remainingMinutes > 5 ? .yellow :
//						.secondary
//					)
            }
            .id(self.arrival.id)
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .padding(.horizontal)
        .onTapGesture { onClick(arrival.direction) }
        
    }
}
