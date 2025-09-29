//
//  LoadingPopUp.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI

struct LoadingPopUp: View {
    var body: some View {
        
        VStack {
            ProgressView("Update Data...")
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 8)
        }
        .transition(.scale.combined(with: .opacity))
        
    }
}
