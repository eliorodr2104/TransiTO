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
			ForEach(self.visibleClusters) { cluster in
				
				if cluster.count == 1 {
					Annotation(
						cluster.stops[0].stopName,
						coordinate: cluster.coordinate
						
					) {
						pinSingleStop(cluster, cluster.stops[0])
							.transition(
								.scale.animation(
									.spring(response: 0.3, dampingFraction: 0.6)
								)
							)
					}
					.annotationTitles(.hidden)

					
				} else {
					Annotation(
						"",
						coordinate: cluster.coordinate
					) {
						pinGroupStops(cluster)
							.transition(
								.scale.animation(
									.spring(response: 0.3, dampingFraction: 0.6)
								)
							)
					}
					.annotationTitles(.hidden)
				}
            }
        }
		.animation(
			.spring(response: 0.4, dampingFraction: 0.7),
			value: visibleClusters
		)
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
		.onMapCameraChange(frequency: .continuous) { context in
			debounceClusterUpdate(context.region)
		}
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
		let dynamicSize = min(35 + (log(Double(cluster.count)) * 6), 60)
		
		HStack {
			Circle()
				.fill(
					LinearGradient(
						gradient: Gradient(
							colors: [
								.blueMarkGradient,
								.blueMark
							]
						),
						startPoint: .top,
						endPoint: .bottom
					)
				)
				.stroke(.thickMaterial, lineWidth: 4)
				.frame(width: dynamicSize, height: dynamicSize)
				.shadow(color: .black.opacity(0.3), radius: 4, y: 2)
			
			VStack(alignment: .leading) {
				
				Text("\(cluster.count) Fermate")
					.contentTransition(.numericText())
					.font(.caption)
					.fontWeight(.bold)
					.fontDesign(.monospaced)
					.shadow(
						color: .black,
						radius: 3
					)
					.lineLimit(1)
			}
				
		}
		.onTapGesture {
			// Move camera to group stop selected and expand
			self.locationManager.moveCamera(
				to: cluster.coordinate,
				zoom: 0.002
			)
		}
    }
    
	/// Show single stop
    @ViewBuilder
    private func pinSingleStop(
		_ cluster: Cluster,
		_ stop	 : Stop
	) -> some View {
		HStack {
			Circle()
				.fill(
					LinearGradient(
						gradient: Gradient(
							colors: [
								.blueMarkGradient,
								.blueMark
							]
						),
						startPoint: .top,
						endPoint: .bottom
					)
				)
				.stroke(.thickMaterial, lineWidth: 4)
				.frame(width: 25, height: 25)
			
			VStack(alignment: .leading) {
				
				Text("Fermata \(stop.stopCode)")
					.font(.caption)
					.fontWeight(.bold)
					.fontDesign(.rounded)
					.shadow(
						color: .black,
						radius: 3
					)
					.lineLimit(1)
				
				Text(stop.stopName)
					.font(.caption)
					.fontWeight(.bold)
					.fontDesign(.rounded)
					.shadow(
						color: .black,
						radius: 3
					)
					.lineLimit(1)
					.frame(maxWidth: 130, alignment: .leading)
			}
				
		}
		.onTapGesture {
			// set stop for get information
			self.navigationViewModel.changeStopFocus(to: cluster.stops[0])
			
			// Move camora to stop
			self.locationManager.moveCamera(
				to: CLLocationCoordinate2D(
					latitude : cluster.stops[0].latitude,
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
			
			// 0.05s, less reactive but more performance
            try? await Task.sleep(nanoseconds: 50_000_000)
			
			if Task.isCancelled { return }
			
            updateVisibleClustersIfNeeded(newRegion: region)
        }
    }
    
    /// Update dynamic cluster
    private func updateVisibleClustersIfNeeded(newRegion: MKCoordinateRegion) {
		
		let span = newRegion.span.latitudeDelta
		
		let hiddenThreshold = 0.02
		let detailThreshold = 0.01
		
		if span > hiddenThreshold {
			if !visibleClusters.isEmpty {
				withAnimation(.easeInOut(duration: 0.3)) {
					visibleClusters = []
				}
			}
			
			return
		}
		
		// If not exit quad tree exit and not update map
		guard let tree = self.gtfsStaticViewModel.quadTree else { return }
        
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
		
		let divider = (span > detailThreshold) ? 7.0 : 20.0
		let minDistanceMeters = latMeters / divider
		
		Task.detached(priority: .userInitiated) {
			
			let stopCodes = await tree.query(range: queryBox)
			
			let rawStops = await MainActor.run {
				return stopCodes.compactMap { code in
					return self.gtfsStaticViewModel.stopsDict[code]
				}
			}
			
			let calculatedClusters = await MapView.clusterStopsByDistance(
				stops: rawStops,
				minDistanceMeters: minDistanceMeters
			)
			
			// Change only clusters changed
			await MainActor.run {
				
				let finalClusters: [Cluster]
				
				if span > detailThreshold {
					finalClusters = calculatedClusters.filter { $0.count > 1 }
					
				} else { finalClusters = calculatedClusters }
				
				withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
					self.visibleClusters = finalClusters
				}
			}
		}
    }
	
	/// Funzione statica ottimizzata: Non rimuove elementi (lento), ma li segna (veloce)
	private static func clusterStopsByDistance(
		stops: [Stop],
		minDistanceMeters: Double
	) -> [Cluster] {
		
		// 1. Ordiniamo per latitudine. Questo è fondamentale per l'uscita anticipata dal ciclo interno.
		let sortedStops = stops.sorted { $0.latitude < $1.latitude }
		let count = sortedStops.count
		
		// 2. Creiamo un registro "veloce" per segnare chi è già in un cluster
		// L'accesso a questo array tramite indice è O(1)
		var isClustered = [Bool](repeating: false, count: count)
		
		var clusters: [Cluster] = []
		
		// Costanti pre-calcolate
		let degreesPerMeter = 1.0 / 111_319.0
		let minDiffDegrees = minDistanceMeters * degreesPerMeter
		let minDiffSquared = minDiffDegrees * minDiffDegrees
		let lonCorrection = 0.707 // cos(45°) approssimato per Torino
		
		// 3. Primo ciclo: Scorriamo le fermate come "candidate principali"
		for i in 0..<count {
			// Se questa fermata è già stata inglobata in un gruppo precedente, saltala (O(1))
			if isClustered[i] { continue }
			
			let mainStop = sortedStops[i]
			
			// Creiamo il nuovo gruppo
			var currentClusterStops: [Stop] = [mainStop]
			isClustered[i] = true // La segniamo come presa
			
			// 4. Secondo ciclo: Cerchiamo vicini solo in avanti (i+1)
			for j in (i+1)..<count {
				if isClustered[j] { continue }
				
				let otherStop = sortedStops[j]
				let dLat = otherStop.latitude - mainStop.latitude
				
				// OTTIMIZZAZIONE CRUCIALE:
				// Poiché l'array è ordinato, se la differenza di latitudine supera il limite,
				// sappiamo che TUTTE le fermate successive saranno troppo lontane.
				// Possiamo rompere il ciclo interno immediatamente.
				if dLat > minDiffDegrees {
					break
				}
				
				// Calcolo distanza semplificato (Pitagora)
				let dLon = (otherStop.longitude - mainStop.longitude) * lonCorrection
				let distSquared = (dLat * dLat) + (dLon * dLon)
				
				if distSquared < minDiffSquared {
					currentClusterStops.append(otherStop)
					isClustered[j] = true // Segniamo anche questa come presa (O(1))
				}
			}
			
			// Calcolo centroide del cluster trovato
			let clusterCount = Double(currentClusterStops.count)
			let avgLat = currentClusterStops.map(\.latitude).reduce(0, +) / clusterCount
			let avgLng = currentClusterStops.map(\.longitude).reduce(0, +) / clusterCount
			
			let anchorID = currentClusterStops.first?.id ?? UUID().uuidString
			
			clusters.append(
				Cluster(
					id	 	  : anchorID,
					stops	  : currentClusterStops,
					coordinate: CLLocationCoordinate2D(
						latitude : avgLat,
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
