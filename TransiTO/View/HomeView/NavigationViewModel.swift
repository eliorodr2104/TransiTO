//
//  NavigationViewModel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 17/09/25.
//

import Foundation
internal import Combine

class NavigationViewModel: ObservableObject {
    
    @Published
	private(set) var stopSelected: AllInfoStop? = nil
	
    @Published
	private(set) var lineSelected: Vehicle? = nil
	
    @Published
	private(set) var stateView: StateView = .home
    
    func changeStateBottomSheet(to newView: StateView) {
        self.stateView = newView
    }
    
    func changeStopFocus(to stop: AllInfoStop) {
        self.stopSelected = stop
        self.stateView 	  = .stopInfo
    }
    
    func changeLineFocus(to line: String, direction: String, typeVehicle: Int) {
        self.lineSelected = Vehicle(
			line: line,
			direction: direction,
			type: TypeVehicle(rawValue: typeVehicle) ?? .bus
		)
        self.stateView = .lineInfo
    }

    func clear() {
        self.stopSelected = nil
		self.lineSelected = nil
        self.stateView    = .home
    }
    
    func clearLineFocus() {
		self.lineSelected = nil
        self.stateView    = .stopInfo
    }
}
