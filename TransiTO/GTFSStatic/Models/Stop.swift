//
//  StopInfo.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 14/09/25.
//

struct Stop: Codable, Identifiable, Equatable, Sendable {
    var id       : String
    let stopCode : String
    let stopName : String
    let city     : String
    let latitude : Double
    let longitude: Double
    let routes   : [RouteInfo]
}
