//
//  ArrivalsRow.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI

struct LineRow: View {
    @EnvironmentObject var arrivalsViewModel: ArrivalsViewmodel
    
    @State private var timeNextArrivalBackup: Int? = nil
    
    let nameStop: String
    let line: Line
    
    private static let tramLines: Set<String> = ["3", "4", "9", "10", "13", "15", "16"]
    
    private var isTram: Bool {
        Self.tramLines.contains(line.number)
    }
    
    var body: some View {
        
        VStack(spacing: 8) {
            
            HStack {
                
                HStack(spacing: 4) {
                    
                    Image(systemName: isTram ? "tram" : "bus")
                    
                    Text(line.number)
                        .lineLimit(1)
                    
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(.tint.opacity(0.25))
                        .overlay(
                            Capsule()
                                .stroke(line.isFocus ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                )
                .foregroundStyle(.tint)
                
                Spacer()
                
                Text(timeNextArrivalBackup != nil ? "\(timeNextArrivalBackup!) min" : "N/A")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .onReceive(arrivalsViewModel.$arrivals) { _ in

                        if let current = arrivalsViewModel.getTimeRemainingArrival(for: nameStop, in: line.number) {
                            timeNextArrivalBackup = current
                        }
                    }
            }
            
        }
        .padding(.vertical, 8)

    }
}
