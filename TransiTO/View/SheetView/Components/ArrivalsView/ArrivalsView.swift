//
//  LineInformationView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 29/09/25.
//

import SwiftUI

struct ArrivalsView: View {
	
	@ObservedObject
	var viewModel: ArrivalsViewModel
    
    @State
	private var remainingTimeArrivals: [Int] = []
	
    @State
	private var arrivals: [Arrival] = []
    
    let lineSelected: Vehicle
    let stopSelected: AllInfoStop
    
    init(
		arrivalsViewModel: ArrivalsViewModel,
		lineSelected	 : Vehicle,
		stopSelected	 : AllInfoStop
	) {
		self.viewModel	  = arrivalsViewModel
        self.lineSelected = lineSelected
        self.stopSelected = stopSelected
    }
    
    var body: some View {
        
        LazyVStack(spacing: 17) {
            
            NextArrivalsView(
                remainingTimeArrivals: remainingTimeArrivals,
                arrivals: arrivals
            )
            
            vehicleStatus
            
        }
        .onAppear {
			self.remainingTimeArrivals = self.viewModel.getAllTimesRemainingArrivals(
				for: self.stopSelected.stopCode,
				in: self.lineSelected.line
            )
            
			self.arrivals = self.viewModel.getLineArrivals(
				for: self.stopSelected.stopCode,
				in: self.lineSelected.line
            )
        }
        .task(id: self.stopSelected.id) {
            
            do {
                while !Task.isCancelled {
                    await self.viewModel.fetchStopArrivals(
						for: self.stopSelected.stopCode
					)
                    
                    self.remainingTimeArrivals = viewModel.getAllTimesRemainingArrivals(
						for: self.stopSelected.stopCode,
						in: self.lineSelected.line
                    )
                    
					self.arrivals = self.viewModel.getLineArrivals(
						for: self.stopSelected.stopCode,
						in: self.lineSelected.line
                    )
                                        
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                }
            }
        }
        
    }
	
	// MARK: - Views
	
	private var vehicleStatus: some View {
		VStack(
			alignment: .leading,
			spacing: 7
		) {
				
			Text("Fermate")
				.font(.title3)
				.fontWeight(.bold)
			
			VStack {
				// Content stop with after and before stops
				Text("Test")
			}
			.padding()
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(.ultraThinMaterial)
			.cornerRadius(25)
			
		}
		.padding(.horizontal)
	}
	
}
