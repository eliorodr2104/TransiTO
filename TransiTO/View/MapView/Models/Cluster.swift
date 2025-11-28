//
//  Cluster.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import CoreLocation

struct Cluster: Identifiable, Equatable {
	let id		  : String
    let stops	  : [Stop]
    let coordinate: CLLocationCoordinate2D
	
    var count: Int { stops.count }
	
	static func == (lhs: Cluster, rhs: Cluster) -> Bool {
		return lhs.id == rhs.id &&
			   lhs.coordinate.latitude == rhs.coordinate.latitude &&
			   lhs.count == rhs.count
	}
}
