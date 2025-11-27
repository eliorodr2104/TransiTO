//
//  InfoStop.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import Foundation

struct InfoStop: Codable, Equatable, Hashable {
    let coordinates: Coordinates
    var lines: [Line]
}

struct Coordinates: Codable, Equatable, Hashable {
    let latitude: Double
    let longitude: Double
}
