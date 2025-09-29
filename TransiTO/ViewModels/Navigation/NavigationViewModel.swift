//
//  NavigationViewModel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 17/09/25.
//

import Foundation
internal import Combine

class NavigationViewModel: ObservableObject {
    
    @Published private(set) var stopSelected: AllInfoStop?                       = nil
    @Published private(set) var lineSelected: (name: String, direction: String)? = nil
    @Published private(set) var stateView   : StateView                          = .EMPTY_HOME
    
    func changeStateBottomSheet(to newView: StateView) {
        self.stateView = newView
    }
    
    func changeStopFocus(to stop: AllInfoStop) {
        self.stopSelected = stop
        self.stateView = .SHOW_STOPS_INFO
    }
    
    func changeLineFocus(to line: String, direction: String) {
        self.lineSelected = (line, direction)
        self.stateView = .SHOW_LINE_INFO
    }

    func clear() {
        self.stopSelected = nil
        self.stateView    = .EMPTY_HOME
    }
    
    func clearLineFocus() {
        self.stateView    = .SHOW_STOPS_INFO
    }
}
