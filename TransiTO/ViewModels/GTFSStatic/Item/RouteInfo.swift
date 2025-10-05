//
//  RouteInfo.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 03/10/25.
//

struct RouteInfo: Decodable, Encodable, Equatable, Hashable {
    let shortName: String
    let type: Int
}
