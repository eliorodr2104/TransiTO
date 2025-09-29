//
//  LineRowStateView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 17/09/25.
//

import SwiftUI

struct LinesAvailablesView: View {
    
    @EnvironmentObject private var navigationViemModel: NavigationViewModel
        
    let stopRoutes: [String]
    let stopCode  : String
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Partenze")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            LazyVStack(spacing: 15) {
                
                ForEach(stopRoutes, id: \.self) { line in
                    
                    LineRowStateView(
                        line: line,
                        stopCode: stopCode
                        
                    ) {
                        self.navigationViemModel.changeLineFocus(to: line)
                    }
                    
                }
            }
        }
        
        
        
    }
}
