//
//  NavigationViewModel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 11/09/25.
//

import SwiftUI
internal import Combine

struct StopDestination: Hashable {
    let stopId: String
}

class NavigationViewModel: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateTo(stopId: String) {
        path.append(StopDestination(stopId: stopId))
        
    }
}
