//
//  CacheMeta.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 03/10/25.
//

import Foundation

// MARK: - Cache meta structure
struct CacheMeta: Codable {
    let fetchedAt         : Date
    let remoteLastModified: String?
}
