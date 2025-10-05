//
//  ArrivalTransport.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import Foundation

struct Arrival: Codable, Identifiable, Hashable {
    
    let id       : UUID = UUID()
    let line     : String
    let schedule : String
    let realtime : Bool
    let direction: String
    
    init(line: String, schedule: String, realtime: Bool, direction: String) {
        self.line      = line
        self.schedule  = schedule
        self.realtime  = realtime
        self.direction = direction
    }
    
    enum CodingKeys: String, CodingKey {
        case line
        case schedule
        case realtime
        case direction
    }
    
}
