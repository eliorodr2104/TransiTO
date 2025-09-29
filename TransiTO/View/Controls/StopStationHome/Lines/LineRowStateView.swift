//
//  StopStationHome.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI

struct LineRowStateView: View {
    
    @EnvironmentObject private var arrivalsViewModel: ArrivalsViewmodel
    
    @State private var firstArrival: Arrival? = nil
    
    let line    : String
    let stopCode: String
    let onClick: () -> Void
    
    var arrivals: [Arrival] {
        arrivalsViewModel.getLineArrivals(for: stopCode, in: line)
    }
    
    
    var body: some View {
        
        Button(action: onClick) {
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 35, height: 35)
                        
                        Image(systemName: "tram")
                            .font(.headline)
                        
                    }
                    
                    Text(line)
                        .font(.headline)
                }
                
                Divider()
                
                HStack {
                    Text(firstArrival?.direction ?? "-")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(arrivalsViewModel.getTimeRemainingArrival(for: stopCode, in: line) ?? 0) min")
                        .font(.subheadline)
                    
                }
                
            }
            .padding(15)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal)
            .onChange(of: arrivals) { _, newArrivals in
                if let first = arrivalsViewModel.getLineArrivals(for: stopCode, in: line).first { firstArrival = first }
            }
            .onAppear { firstArrival = arrivals.first }
        }
    }
}

#Preview {
    LineRowStateView(line: "9", stopCode: "558") {
        
    }
}
