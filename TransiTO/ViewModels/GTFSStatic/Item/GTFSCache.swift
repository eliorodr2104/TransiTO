//
//  GTFSCache.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import Foundation

struct GTFSCache: Codable {
    let stops: [String: StopInfo]
    let fetchedAt: Date
}
