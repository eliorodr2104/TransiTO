//
//  LineInformationView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 29/09/25.
//

import SwiftUI

struct CurrentArrivalInfoView: View {
    @EnvironmentObject private var arrivalsViewModel: ArrivalsViewmodel
    
    @State private var remainingTimeArrivals: [Int]     = []
    @State private var arrivals             : [Arrival] = []
    
    let lineSelected: (name: String, direction: String, typeVehicle: Int)
    let stopSelected: AllInfoStop
    
    init(lineSelected: (name: String, direction: String, typeVehicle: Int), stopSelected: AllInfoStop) {
        self.lineSelected = lineSelected
        self.stopSelected = stopSelected
    }
    
    var body: some View {
        
        LazyVStack(spacing: 17) {
            
            ListNextArrivalsView(
                remainingTimeArrivals: remainingTimeArrivals,
                arrivals: arrivals
            )
            
            VehicleStatusView()
            
        }
        .onAppear {
            self.remainingTimeArrivals = arrivalsViewModel.getAllTimesRemainingArrivals(
                for: stopSelected.stopCode,
                in: lineSelected.name
            )
            
            self.arrivals = arrivalsViewModel.getLineArrivals(
                for: stopSelected.stopCode,
                in: lineSelected.name
            )
        }
        .task(id: self.stopSelected.id) {
            
            do {
                while !Task.isCancelled {
                    await self.arrivalsViewModel.fetchStopArrivals(for: self.stopSelected.stopCode)
                    
                    self.remainingTimeArrivals = arrivalsViewModel.getAllTimesRemainingArrivals(
                        for: stopSelected.stopCode,
                        in: lineSelected.name
                    )
                    
                    self.arrivals = arrivalsViewModel.getLineArrivals(
                        for: stopSelected.stopCode,
                        in: lineSelected.name
                    )
                                        
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                }
            }
        }
        
    }
}
