//
//  RowAddLine.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 12/09/25.
//

import SwiftUI

struct RowAddLine: View {
    
    private static let tramLines: Set<String> = ["3", "4", "7", "9", "10", "13", "15", "16", "79",]
    
    @Binding private var selected: String
    
    let lineNumber: String
    let usageState: Bool
    
    init(lineNumber: String, selected: Binding<String>, isAlreadyUsage: Bool) {
        self.lineNumber = lineNumber
        self._selected = selected
        self.usageState = isAlreadyUsage
    }
    
    private var isTram: Bool {
        Self.tramLines.contains(lineNumber)
    }
    
    private var isFocus: Bool {
        selected == lineNumber
    }
    
    var body: some View {
        
        Button(action: { if !usageState { selected = lineNumber } }) {
            
            HStack {
                
                HStack {
                    
                    Image(systemName: isTram ? "tram" : "bus")
                    
                    Text(lineNumber)
                    
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.tint.opacity(0.20)))
                .foregroundStyle(.tint)
                
                Spacer()
                
                Image(systemName: isFocus || usageState ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isFocus || usageState ? .quaternary : .primary)
            }
        }
        .disabled(usageState)
        
    }
}
