//
//  BusStop.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 12/09/25.
//

import Foundation

// MARK: - BusStop
struct BusStop: Codable, Hashable, Identifiable {
    var id: String { stopCode }
    let stopCode: String
    let stopName: String
    let city: String
    let routes: [String]
}
