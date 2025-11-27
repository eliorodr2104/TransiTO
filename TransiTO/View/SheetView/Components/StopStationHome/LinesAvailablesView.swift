//
//  LineRowStateView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 17/09/25.
//

import SwiftUI

struct LinesAvailablesView: View {
    
    @ObservedObject
	var viewModel: ArrivalsViewModel
        
	var changeLineFocus: (
		_ line: String,
		_ direction: String,
		_ typeVehicle: Int
	) -> Void
	
    let stopInfo: AllInfoStop
    
    var body: some View {
        let lastItem = stopInfo.routes.last
        
        // List for rapresenting line stops
        VStack(alignment: .leading) {
            
            // Title list
            Text("Partenze")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // Lazy vertical stack
            LazyVStack(spacing: 14) {
                
                ForEach(stopInfo.routes, id: \.self) { line in
                    /// Get arrivals for view model
					let arrival = self.viewModel.getLineArrivals(
						for: stopInfo.stopCode,
						in: line.shortName
					).first
                                        
                    if let currentArrival = arrival {
                        LineRowStateView(
							remainingArrivalTime: self.viewModel.getTimeRemainingArrival,
                            arrival: currentArrival,
                            stopCode: stopInfo.stopCode,
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
                        .id(line)
                        .padding(.bottom, lastItem == line ? 25 : 0)
                    }
                    
                }
            }
        }
        .task(id: self.stopInfo.id) {
            
            do {
                while !Task.isCancelled {
                    await self.viewModel.fetchStopArrivals(
						for: stopInfo.stopCode
					)
                                        
                    try? await Task.sleep(
						nanoseconds: 45_000_000_000 // 45_000_000_000 = 45s
					)
                }
            }
        }
    }
}
