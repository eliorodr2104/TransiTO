//
//  QuadTree.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import CoreLocation

/// Quad tree for divide the map in sections and sub sections
class QuadTree<T> {
    private let capacity: Int
    private let bounds: BoundingBox
    private var points: [(coordinate: CLLocationCoordinate2D, value: T)] = []
    private var divided = false
    
    private var northeast: QuadTree?
    private var northwest: QuadTree?
    private var southeast: QuadTree?
    private var southwest: QuadTree?
    
    init(bounds: BoundingBox, capacity: Int = 4) {
        self.bounds = bounds
        self.capacity = capacity
    }
    
    func insert(
		coordinate: CLLocationCoordinate2D,
		value: T
	) -> Bool {
		
        guard bounds.contains(coordinate) else { return false }
        
        if points.count < capacity {
            points.append((coordinate, value))
            return true
        }
        
        if !divided { subdivide() }
        
        if northeast!.insert(
			coordinate: coordinate,
			value: value
		) { return true }
		
        if northwest!.insert(
			coordinate: coordinate,
			value: value
		) { return true }
		
        if southeast!.insert(
			coordinate: coordinate,
			value: value
		) { return true }
		
        if southwest!.insert(
			coordinate: coordinate,
			value: value
		) { return true }
        
        return false
    }
    
    private func subdivide() {
        let midLat = (bounds.minLat + bounds.maxLat) / 2
        let midLng = (bounds.minLng + bounds.maxLng) / 2
        
        northeast = QuadTree(
			bounds: BoundingBox(
				minLat: midLat,
				maxLat: bounds.maxLat,
				minLng: midLng,
				maxLng: bounds.maxLng
			),
			capacity: capacity
		)
		
        northwest = QuadTree(
			bounds: BoundingBox(
				minLat: midLat,
				maxLat: bounds.maxLat,
				minLng: bounds.minLng,
				maxLng: midLng
			),
			capacity: capacity
		)
		
        southeast = QuadTree(
			bounds: BoundingBox(
				minLat: bounds.minLat,
				maxLat: midLat,
				minLng: midLng,
				maxLng: bounds.maxLng
			),
			capacity: capacity
		)
		
        southwest = QuadTree(
			bounds: BoundingBox(
				minLat: bounds.minLat,
				maxLat: midLat,
				minLng: bounds.minLng,
				maxLng: midLng
			),
			capacity: capacity
		)
        
        divided = true
    }
    
    func query(range: BoundingBox) -> [T] {
		var results: [T] = []
		results.reserveCapacity(100)
		query(range: range, results: &results)
		return results
    }
	
	private func query(range: BoundingBox, results: inout [T]) {
		if !bounds.intersects(range) { return }
		
		for point in points {
			if range.contains(point.coordinate) {
				results.append(point.value)
			}
		}
		
		if divided {
			northeast?.query(range: range, results: &results)
			northwest?.query(range: range, results: &results)
			southeast?.query(range: range, results: &results)
			southwest?.query(range: range, results: &results)
		}
	}
}
