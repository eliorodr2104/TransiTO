//
//  AddFavoriteLine.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI

struct AddFavoriteLine: View {
    
    @EnvironmentObject var storageFavorite: StorageFavoriteViewmodel
    @EnvironmentObject var busStops: TransportStopsViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var lineNumber = ""
    
    let numberStop: String
    
    init(to numberStop: String) {
        self.numberStop = numberStop
    }
    
    var body: some View {
        
        List(busStops.getRoutesForStop(stopCode: numberStop), id: \.self) { line in
            let lineTemp = line.replacingOccurrences(of: "U", with: "")
            RowAddLine(lineNumber: lineTemp, selected: $lineNumber, isAlreadyUsage: storageFavorite.getLine(in: numberStop, for: lineTemp) != nil)
                
        }
        .listStyle(.carousel)
        .toolbar {
            if !lineNumber.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveLine) {
                        
                        Label("Add item", systemImage: "checkmark")
                            .labelStyle(.iconOnly)
                        
                    }
                }
            }
        }
        .navigationTitle("Add line")
        
    }
    
    private func saveLine() {
        guard !lineNumber.isEmpty else {
            return
        }
        
        storageFavorite.addLine(to: numberStop, lineNumber: lineNumber)

        dismiss()
    }
}
