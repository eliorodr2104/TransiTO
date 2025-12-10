//
//  LineRowStateView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 17/09/25.
//

import SwiftUI

struct DeparturesLinesView: View {
    
    @ObservedObject
	var viewModel: ArrivalsViewModel
        
	var changeLineFocus: (
		_ line		 : String,
		_ direction  : String,
		_ typeVehicle: TypeVehicle
	) -> Void
	
    let stop: Stop
    
    var body: some View {
        let lastItem = stop.routes.last
        
        // List for rapresenting line stops
        VStack(alignment: .leading) {
            
            // Title list
            Text("Partenze")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // Lazy vertical stack
            LazyVStack(spacing: 14) {
                
				ForEach(stop.routes, id: \.id) { line in
                    /// Get arrivals for view model
					
					let arrival = self.viewModel.getFirstArrival(
						in: stop.stopCode,
						line.shortName
					)
					
					if let currentArrival = arrival {
						DepartureRowView(
							arrival: currentArrival,
							stopCode: stop.stopCode,
							typeVehicle: line.type
							
						) { direction in
							if let direct = direction {
								self.changeLineFocus(
									line.shortName,
									direct,
									line.type
								)
							}
						}
						.padding(.bottom, lastItem == line ? 25 : 0)
					}
                    
                }
            }
        }
		.task(
			id: self.stop.id,
			handleStopTastk
		)
    }
	
	// MARK: - Handles
	
	private func handleStopTastk() async {
		do {
			while !Task.isCancelled {
				await self.viewModel.fetchStopArrivals(
					for: stop.stopCode
				)
									
				try? await Task.sleep(
					nanoseconds: 45_000_000_000 // 45_000_000_000 = 45s
				)
			}
		}
	}
}

