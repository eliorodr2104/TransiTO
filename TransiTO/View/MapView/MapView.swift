//
//  MapView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 14/09/25.
//

import SwiftUI
import MapKit
internal import Combine

/// Show Map and pins for all stops
struct MapView: View {
    
    /// View models inject in enviroment
    @EnvironmentObject
	private var gtfsStaticViewModel: GTFSStaticViewModel
	
    @ObservedObject
	var locationManager: LocationManager
	
    @ObservedObject
	var navigationViewModel: NavigationViewModel
    
    @State
	private var hasCenteredOnUser: Bool = false
	
    @State
	private var visibleClusters: [Cluster] = []
    
    @State
	private var clusterUpdateTask: Task<Void, Never>?
	
    @State
	private var visibleRegion: MKCoordinateRegion?
    
    private static let threshold: Double = 0.001
	
    private static let margin: Double = 0.01
    
    var body: some View {
        
        // Pass current posution camero to map
        Map(position: self.$locationManager.cameraPosition) {
			
			// User position in realtime
            UserAnnotation()
            
            // Create all pins
            ForEach(visibleClusters) { cluster in
				
				if cluster.count == 1 {
					Annotation(
						cluster.stops[0].stopName,
						coordinate: cluster.coordinate
						
					) { pinSingleStop(cluster) }
					
				} else {
					Annotation(
						"",
						coordinate: cluster.coordinate
					) { pinGroupStops(cluster) }
				}
            }
        }
        .mapStyle( // Style pins
			.standard(
				pointsOfInterest: PointOfInterestCategories.excludingAll
			)
		)
        .mapControlVisibility(.visible)
        .frame(minWidth: 1, minHeight: 1)
        .onAppear {
			let region = self.locationManager.cameraPosition.region ??
											      MKCoordinateRegion()
			
            updateVisibleClustersIfNeeded(newRegion: region)
        }
        .onMapCameraChange { context in debounceClusterUpdate(context.region) }
        .onReceive(locationManager.$userLocation.compactMap { $0 }) { coordinate in
            guard !hasCenteredOnUser else { return }
            self.locationManager.moveCamera(to: coordinate)
            hasCenteredOnUser = true
        }
    }
	
	// MARK: - Views
    
	/// Single pin for groups stops
    @ViewBuilder
    private func pinGroupStops(_ cluster: Cluster) -> some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 30, height: 30)
            
            // Number stop contains the group
            Text("\(cluster.count)")
                .foregroundColor(.white)
                .bold()
        }
		.onTapGesture {
			// Move camera to group stop selected and expand
			self.locationManager.moveCamera(to: cluster.coordinate)
		}
    }
    
	/// Show single stop
    @ViewBuilder
    private func pinSingleStop(_ cluster: Cluster) -> some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 20, height: 20)
            .onTapGesture {
                // set stop for get information
                self.navigationViewModel.changeStopFocus(to: cluster.stops[0])
                
                // Move camora to stop
                self.locationManager.moveCamera(
                    to: CLLocationCoordinate2D(
                        latitude: cluster.stops[0].latitude,
                        longitude: cluster.stops[0].longitude
                    )
                )
            }
    }
	
	// MARK: - Handlers
    
    /// Update map and get in consideartion the last update
    private func debounceClusterUpdate(_ region: MKCoordinateRegion) {
        clusterUpdateTask?.cancel()
        clusterUpdateTask = Task {
            try? await Task.sleep(
				nanoseconds: 500_000_000 // 0.5s, less reactive but more performance
			)
			
            updateVisibleClustersIfNeeded(newRegion: region)
        }
    }
    
    /// Update dynamic cluster
    private func updateVisibleClustersIfNeeded(newRegion: MKCoordinateRegion) {
        
        // If not exit quad tree exit and not update map
        guard let tree = gtfsStaticViewModel.quadTree else { return }
        
        // Get old region if exist
        if let oldRegion = visibleRegion {
            let centerChanged = abs(
				newRegion.center.latitude - oldRegion.center.latitude
				
			) > Self.threshold || abs(
				newRegion.center.longitude - oldRegion.center.longitude
				
			) > Self.threshold
            
            let spanChanged = abs(
				newRegion.span.latitudeDelta - oldRegion.span.latitudeDelta
				
			) > Self.threshold || abs(
				newRegion.span.longitudeDelta - oldRegion.span.longitudeDelta
				
			) > Self.threshold
            
            // not calculate the position if exist
            if !centerChanged && !spanChanged { return }
        }
        
        // Set new region
        visibleRegion = newRegion
        
        // Set query for Quadtree struct
        let queryBox = BoundingBox(
            minLat: newRegion.center.latitude -
					newRegion.span.latitudeDelta/2 -
					Self.margin,
			
            maxLat: newRegion.center.latitude +
					newRegion.span.latitudeDelta/2 +
					Self.margin,
			
            minLng: newRegion.center.longitude -
					newRegion.span.longitudeDelta/2 -
					Self.margin,
			
            maxLng: newRegion.center.longitude +
					newRegion.span.longitudeDelta/2 +
					Self.margin
        )
        
        // Min distance adaptive
        let latMeters = newRegion.span.latitudeDelta * 111_000
        let minDistanceMeters = latMeters / 15
        
        let newClusters = clusterStopsByDistance(
			stops: tree.query(range: queryBox),
			minDistanceMeters: minDistanceMeters
		)
        
        // Change only clusters changed
        withAnimation(.easeInOut(duration: 0.3)) {
            var updated: [Cluster] = []
            
            for new in newClusters {
                if let old = visibleClusters.first(where: { $0.id == new.id }) {
                    
                    if old.coordinate.latitude != new.coordinate.latitude ||
					   old.coordinate.longitude != new.coordinate.longitude {
						
						updated.append(new)
                        
                    } else { updated.append(old) }
                    
                } else { updated.append(new) }
            }
            
            visibleClusters = updated
        }
    }
    
    /// Clustering min distance based
    private func clusterStopsByDistance(
		stops: [AllInfoStop],
		minDistanceMeters: Double
	) -> [Cluster] {
		
        var clusters: [Cluster] = []
        var unvisited = stops
        
        while !unvisited.isEmpty {
            let stop = unvisited.removeFirst()
            var clusterStops: [AllInfoStop] = [stop]
            
            unvisited.removeAll { other in
                if distance(
                    CLLocationCoordinate2D(
						latitude : stop.latitude,
						longitude: stop.longitude
					),
                    CLLocationCoordinate2D(
						latitude : other.latitude,
						longitude: other.longitude
					)
                    
                ) < minDistanceMeters {
					
                    clusterStops.append(other)
                    return true
                }
				
                return false
            }
            
            // Center cluster
            let avgLat = clusterStops
				.map(\.latitude)
				.reduce(0, +) / Double(clusterStops.count)
			
            let avgLng = clusterStops
				.map(\.longitude)
				.reduce(0, +) / Double(clusterStops.count)
			
            clusters.append(
				Cluster(
					stops: clusterStops,
					coordinate: CLLocationCoordinate2D(
						latitude: avgLat,
						longitude: avgLng
					)
				)
			)
        }
        
        return clusters
    }
    
    /// Coordinate distance
    private func distance(
		_ a: CLLocationCoordinate2D,
		_ b: CLLocationCoordinate2D
	) -> Double {
		
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        
        return locA.distance(from: locB)
    }
    
}
