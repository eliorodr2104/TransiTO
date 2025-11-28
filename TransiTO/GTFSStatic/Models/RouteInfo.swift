//
//  RouteInfo.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 03/10/25.
//

import Foundation

struct RouteInfo: Codable, Identifiable, Sendable, Hashable {
	var id		 : UUID = UUID()
    let shortName: String
    let type	 : TypeVehicle
	
	static func == (lhs: RouteInfo, rhs: RouteInfo) -> Bool {
		return lhs.shortName == rhs.shortName && lhs.type == rhs.type
	}
		
	func hash(into hasher: inout Hasher) {
		hasher.combine(shortName)
		hasher.combine(type)
	}
}
