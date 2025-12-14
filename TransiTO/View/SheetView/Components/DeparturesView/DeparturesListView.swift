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
    
    @State
    private var firstLoading = false
        
	var changeLineFocus: (
		_ line		 : String,
		_ direction  : String,
		_ typeVehicle: TypeVehicle
	) -> Void
	
    let stop: Stop
    
    var stopNotAvailable: Bool {
        self.viewModel.arrivals[stop.stopCode]?.isEmpty ?? true && firstLoading
    }
    
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
                
                if !stopNotAvailable {
                    DepartureRowView(
                        stopCode: "",
                        typeVehicle: .metro
                    ) { _ in }
                    
                } else { stopNotAvailableView(stop.stopName) }
                
                ForEach(self.stop.routes, id: \.id) { line in
                                        
                    /// Get arrivals for view model
                    let arrival = self.viewModel.getFirstArrival(
                        in: stop.stopCode,
                        line.shortName
                    )
                    
                    if arrival != Arrival.placeHolder {
                        DepartureRowView(
                            arrival    : arrival,
                            stopCode   : stop.stopCode,
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
			handleStopTask
		)
    }
    
    // MARK: - View
    
    @ViewBuilder
    private func stopNotAvailableView(_ stopName: String) -> some View {
        VStack(
            alignment: .leading,
            spacing  : 10
        ) {
            
            HStack(
                alignment: .firstTextBaseline,
                spacing  : 7
            ) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                
                Text(stopName)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Divider()
            
            HStack {
                Text("La fermata non è al momento disponibile")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

            }
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .padding(.horizontal)
    }
	
	// MARK: - Handles
	
	private func handleStopTask() async {
		do {
            while !Task.isCancelled {
				await self.viewModel.fetchStopArrivals(
					for: stop.stopCode
				)
                
                if !self.firstLoading {
                    try? await Task.sleep(
                        nanoseconds: 2_000_000_000 // 45_000_000_000 = 45s
                    )
                }
                
                self.firstLoading = true
                									
				try? await Task.sleep(
					nanoseconds: 45_000_000_000 // 45_000_000_000 = 45s
				)
			}
		}
	}
}

