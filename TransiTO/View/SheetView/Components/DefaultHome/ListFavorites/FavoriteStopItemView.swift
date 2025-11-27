//
//  FavoriteStopItemView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI

struct FavoriteStopItemView: View {
    
    let nameStop: String
    let onClick: () -> Void
    
    var body: some View {
        
        ZStack {
            
            Circle()
                .frame(width: 65, height: 65)
                .foregroundStyle(.green.opacity(0.2))
            
            Text(nameStop)
                .font(.title3)
                .foregroundStyle(.green)
            
        }
        .onTapGesture(perform: onClick)
        
    }
}
