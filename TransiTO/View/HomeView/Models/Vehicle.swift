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

enum TypeVehicle: Int {
	case tram  = 0
	case metro = 2
	case bus   = 3
	
	var name: String {
		
		switch self {
			case .bus  : "Bus"
			case .tram : "Tram"
			case .metro: "Metro"
		}
	}
}
