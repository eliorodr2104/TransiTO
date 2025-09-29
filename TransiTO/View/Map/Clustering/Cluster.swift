//
//  Cluster.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import CoreLocation

/// Cluster Struct
struct Cluster: Identifiable {
    let stops: [AllInfoStop]
    let coordinate: CLLocationCoordinate2D
    var count: Int { stops.count }
    
    var id: String { stops.map(\.id).sorted().joined(separator: "-") }
}
