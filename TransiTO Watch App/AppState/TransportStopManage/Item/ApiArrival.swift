//
//  ApiResponse.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 12/09/25.
//

import Foundation

struct ApiArrival: Codable, Identifiable, Hashable {
    
    let id = UUID()
    let line: String
    let lineAlias: String
    let realtimeArrivals: [String]
    let scheduledArrivals: String
    let direction: String
    let shortDirection: String
    let basin: String
    let regulation: String
    let hasAlert: Bool
    let programmedArrivals: [String]
    
    enum CodingKeys: String, CodingKey {
        case line = "Linea"
        case lineAlias = "LineaAlias"
        case realtimeArrivals = "PassaggiRT"
        case scheduledArrivals = "Passaggi"
        case direction = "Direzione"
        case shortDirection = "DirezioneBreve"
        case basin = "Bacino"
        case regulation = "Regol"
        case hasAlert = "Avviso"
        case programmedArrivals = "PassaggiPR"
    }
    
    var allArrivals: [String] {
        return realtimeArrivals.isEmpty ? programmedArrivals : realtimeArrivals
    }
    
}
