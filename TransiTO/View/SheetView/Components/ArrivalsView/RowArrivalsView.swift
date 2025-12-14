//
//  ListNextArrivalsView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 29/09/25.
//

import SwiftUI

struct NextArrivalsView: View {
    let arrivals: [Arrival]
	    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Text("Partenze previste:")
                    .font(.title3)
                    .fontWeight(.semibold)
                
				if self.arrivals.count >= 3 {
                    Spacer()
                    
					let minutes = self.arrivals[1].remainingMinutes -
								  self.arrivals[2].remainingMinutes
					
					Text("Ogni \(abs(minutes)) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontDesign(.rounded)
                        // .fontDesign(.monospaced) -> Not pretty font
                }
            }
            
            ScrollView(
				.horizontal,
				showsIndicators: false
			) {
                LazyHStack(spacing: 12) {
					
					ForEach(self.arrivals) { item in
                        itemArrival(item)
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
	
	@ViewBuilder
	private func itemArrival(_ arrival: Arrival) -> some View {
		VStack {
			Text("\(arrival.remainingMinutes) min")
                .fontWeight(.semibold)
				.font(.subheadline)
			
			Text(arrival.realtime ? "In orario" : "Programmato")
				.foregroundStyle(
                    arrival.realtime ? Color.accentColor : .secondary
                )
				.font(.caption)
		}
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
}
