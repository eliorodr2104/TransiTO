//
//  LocationManager.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI
import MapKit
import CoreLocation

import Foundation
internal import Combine

/// ViewModel for manage location iPhone
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    /// User location realtime
    @Published
	var userLocation: CLLocationCoordinate2D?
    
    /// Position camera
    @Published
	var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
				latitude: 45.0703,
				longitude: 7.6869
			),
            span: MKCoordinateSpan(
				latitudeDelta: 0.005,
				longitudeDelta: 0.005
			)
        )
    )
    
    override init() {
        super.init()
        
        manager.delegate        = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    /// Set location manager
    func locationManager(
		_ manager: CLLocationManager,
		didUpdateLocations locations: [CLLocation]
	) {
        guard let loc = locations.last else { return }
        
        Task { self.userLocation = loc.coordinate }
    }
    
    /// Error func message
    func locationManager(
		_ manager: CLLocationManager,
		didFailWithError error: Error
		
	) { print("Error Location:", error) }
    
    /// Set focus comera
    func setFocusUserLocation() {
        if let userLocation = userLocation {
            moveCamera(to: userLocation)
        }
    }
    
    /// Move camera to coordinate position
    func moveCamera(
		to coordinate: CLLocationCoordinate2D,
		zoom: Double = 0.001
	) {
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(
						latitudeDelta: zoom,
						longitudeDelta: zoom
					)
                )
            )
        }
    }
}
