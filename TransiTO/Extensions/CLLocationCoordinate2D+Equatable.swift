//
//  CLLocationCoordinate2D+.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 26/11/25.
//

import MapKit

/// Extend and add Equatable extension for use .onChange()
extension CLLocationCoordinate2D: @retroactive Equatable {
	
	/// Func to make equatable CLLocationCoordinate2D
	public static func == (
		lhs: CLLocationCoordinate2D,
		rhs: CLLocationCoordinate2D
	) -> Bool {
		lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
	}
}
