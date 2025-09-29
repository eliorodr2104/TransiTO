//
//  StopStationHome.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI

struct LineRowStateView: View {
    
    /// Enviroment object for manage arrivals.
    @EnvironmentObject private var arrivalsViewModel: ArrivalsViewmodel
    
    // Attributes struct
    let line    : String
    let stopCode: String
    let onClick : (_ direction: String?) -> Void
    
    var body: some View {
        /// Get arrivals for view model
        let arrival = arrivalsViewModel.getLineArrivals(for: stopCode, in: line).first

        VStack(alignment: .leading, spacing: 10) {
            
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                ZStack {
                    Circle()
                        .fill(.tint)
                        .frame(width: 35, height: 35)
                    
                    Image(systemName: "tram")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                }
                
                Text(line)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Divider()
            
            HStack {
                Text(arrival?.direction ?? "-")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                
                Spacer()
                
                Text("\(arrivalsViewModel.getTimeRemainingArrival(for: stopCode, in: line) ?? 0) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
            }
            
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .padding(.horizontal)
        .onTapGesture { onClick(arrival?.direction) }
        
    }
}

#Preview {
    LineRowStateView(line: "9", stopCode: "558") { _ in
        
    }
}
