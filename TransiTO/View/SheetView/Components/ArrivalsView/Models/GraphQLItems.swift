//
//  GraphQLItems.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import Foundation

struct GraphQLResponse: Codable {
    let data: GraphQLData
}

struct GraphQLData: Codable {
    let stop: GraphQLStop?
}

struct GraphQLStop: Codable {
    let stops: [GraphQLStopTime]
}

struct GraphQLStopTime: Codable {
    let serviceDay: Int
    let realtimeDeparture: Int
    let realtime: Bool
    let trip: GraphQLTrip
}

struct GraphQLTrip: Codable {
    let tripHeadsign: String
    let wheelchairAccessible: String
    let occupancyStatus: String
    let pattern: GraphQLPattern
}

struct GraphQLPattern: Codable {
    let route: GraphQLRoute
}

struct GraphQLRoute: Codable {
    let gtfsId: String
    let shortName: String
}
