//
//  NavigationViewModel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 17/09/25.
//

import Foundation
internal import Combine

class NavigationViewModel: ObservableObject {
    
    @Published private(set) var stopSelected: StopInfo? = nil
    @Published private(set) var lineSelected: String?   = nil
    @Published private(set) var stateView   : StateView     = .EMPTY_HOME
    
    func changeStopFocus(to stop: StopInfo) {
        self.stopSelected = stop
        self.stateView = .SHOW_STOPS_INFO
    }
    
    func changeLineFocus(to line: String) {
        self.lineSelected = line
        self.stateView = .SHOW_LINE_INFO
    }

    func clear() {
        self.stateView    = .EMPTY_HOME
    }
    
    func clearLineFocus() {
        self.stateView    = .SHOW_STOPS_INFO
    }
}
