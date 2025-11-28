//
//  Vehicle.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 26/11/25.
//

struct Vehicle: Equatable {
	let line	 : String
	let direction: String
	let type	 : TypeVehicle
	
}

enum TypeVehicle: Int, Sendable, Codable {
	case tram  = 0
	case metro = 1
	case bus   = 3
	
	var name: String {
		
		switch self {
			case .bus  : "Bus"
			case .tram : "Tram"
			case .metro: "Metro"
		}
	}
	
	var icon: String {
		switch self {
			case .bus  : "bus.fill"
			case .tram : "tram.fill"
			case .metro: "m.square.fill"
		}
	}
}
