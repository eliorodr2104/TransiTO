//
//  BoundingBox.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import CoreLocation

/// Struct to manage clusters points
struct BoundingBox {
    let minLat: Double
    let maxLat: Double
    let minLng: Double
    let maxLng: Double
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude  >= minLat &&
        coordinate.latitude  <= maxLat &&
        coordinate.longitude >= minLng &&
        coordinate.longitude <= maxLng
    }
    
    func intersects(_ other: BoundingBox) -> Bool {
        !(other.minLng > maxLng || other.maxLng < minLng ||
          other.minLat > maxLat || other.maxLat < minLat)
    }
}
