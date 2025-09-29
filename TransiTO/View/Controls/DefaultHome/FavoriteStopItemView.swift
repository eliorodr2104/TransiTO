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
                .frame(width: 35, height: 35)
            
            Text(nameStop)
            
        }
        .onTapGesture(perform: onClick)
        
    }
}
