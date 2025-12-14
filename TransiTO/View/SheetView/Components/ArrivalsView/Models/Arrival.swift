//
//  ArrivalTransport.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import Foundation

struct Arrival: Codable, Identifiable, Hashable, Equatable {
    
    let id       		: UUID = UUID()
    let line     		: String
    let schedule 		: String
    let realtime	    : Bool
    let direction		: String
	var remainingMinutes: Int
    
    init(
		line			: String,
		schedule		: String,
		realtime		: Bool,
		direction		: String,
		remainingMinutes: Int = 0
	) {
        self.line      		  = line
        self.schedule  		  = schedule
        self.realtime  		  = realtime
        self.direction 		  = direction
		self.remainingMinutes = remainingMinutes
    }
    
    enum CodingKeys: String, CodingKey {
        case line
        case schedule
        case realtime
        case direction
		case remainingMinutes
    }
    
    static let placeHolder = Arrival(
        line: "9",
        schedule: "21/49/2444",
        realtime: true,
        direction: "destination"
    )
    
}
