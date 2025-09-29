//
//  StopInfo.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 14/09/25.
//

struct AllInfoStop: Codable, Identifiable, Equatable {
    var id       : String { stopId }
    let stopId   : String
    let stopCode : String
    let stopName : String
    let city     : String
    let latitude : Double
    let longitude: Double
    let routes   : [String]
}
