//
//  LineRowStateView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 17/09/25.
//

import SwiftUI

struct LinesAvailablesView: View {
    
    @EnvironmentObject private var navigationViemModel: NavigationViewModel
    @EnvironmentObject private var arrivalsViewModel: ArrivalsViewmodel
        
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
                    let arrival = arrivalsViewModel.getLineArrivals(for: stopInfo.stopCode, in: line.shortName).first
                                        
                    if let currentArrival = arrival {
                        LineRowStateView(
                            arrival: currentArrival,
                            stopCode: stopInfo.stopCode,
                            typeVehicle: line.type
                            
                        ) { direction in
                            if let direct = direction {
                                self.navigationViemModel.changeLineFocus(
                                    to: line.shortName,
                                    direction: direct,
                                    typeVehicle: line.type
                                )
                            }
                        }
                        .id(line)
                        .padding(.bottom, lastItem == line ? 25 : 0)
//                        .onAppear {
//                            print("Line: \(line.shortName) is type \(line.type)")
//                        }
                    }
                    
                }
            }
        }
        .task(id: self.navigationViemModel.stopSelected?.id) {
            guard let stopInfo = self.navigationViemModel.stopSelected else { return }
            
            do {
                while !Task.isCancelled {
                    await self.arrivalsViewModel.fetchStopArrivals(for: stopInfo.stopCode)
                                        
                    try? await Task.sleep(nanoseconds: 45_000_000_000) // 45_000_000_000 = 45s
                }
            }
        }
    }
}
