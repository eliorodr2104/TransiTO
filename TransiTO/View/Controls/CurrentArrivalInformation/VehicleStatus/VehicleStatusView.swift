//
//  VehicleStatusView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 04/10/25.
//

import SwiftUI

struct VehicleStatusView: View {
    var body: some View {
        
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
