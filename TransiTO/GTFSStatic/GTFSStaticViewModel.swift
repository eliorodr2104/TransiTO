//
//  GTFSStaticViewModel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 14/09/25.
//

import Foundation
import ZIPFoundation
import CoreLocation
internal import Combine

@MainActor
class GTFSStaticViewModel: ObservableObject {
    
    /// Published stops information,
	/// this is dictionary for computational complexity O(1)
    @Published
	private(set) var stopsDict: [String: Stop] = [:]
    
    /// Download and processing state
    @Published
	private(set) var isLoading: Bool = false
    
    /// State for search stop on UI
    @Published
	private(set) var searchResults: [Stop] = []
	
    @Published
	var searchQuery: String = ""
	
    @Published
	private var isSearchIndexing: Bool = false

	/// Quad tree for manage stops on map
	private(set) var quadTree: QuadTree<String>?
	
    /// Config setup
    private static let gtfsURL: URL? = URL(
		string: "https://www.gtt.to.it/open_data/gtt_gtfs.zip"
	) ?? nil
	
    private let cacheDirectory: URL
    private let processedDataURL: URL
    private let metaURL: URL
    private let cacheExpirationDays: UInt8 = 7
    
    /// Seearch service
    private let searchIndex = StopsSearchIndexService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constructor View model
    init() {
        // Get cache data if exist
        self.cacheDirectory = FileManager
								.default
								.temporaryDirectory
								.appendingPathComponent("GTT_GTFS")
		
        self.processedDataURL = cacheDirectory
                                    .appendingPathComponent("gtfs_cache.json")
		
        self.metaURL = cacheDirectory
							.appendingPathComponent("gtfs_cache_meta.json")
        
        // Set loading data true
        self.isLoading = true
        
        $searchQuery
            .debounce(
                for: .milliseconds(150),
                scheduler: RunLoop.main
            )
            .removeDuplicates()
            .sink { [weak self] query in
                
                // Control if query exist for search value
                guard let self = self else { return }
                let currentQuery = query.trimmingCharacters(
					in: .whitespacesAndNewlines
				)
                
                if currentQuery.isEmpty { self.searchResults = []; return }
                
                // launch Task to call async search
                Task { [weak self] in
                    guard let self = self else { return }
                    
                    let results = await self.searchIndex.search(
						currentQuery,
						maxResults: 100
					)
					
                    self.searchResults = results
                }

            }
            .store(in: &cancellables) // Store value in cancellables
        
        
        // Load data or update
        Task { await
			loadGTFSData()
            buildQuadTree()
            buildSearchIndex()
        }
    }
    
    // MARK: - Searching Func's
    
    /// Helper to get sorted array of stops when needed
    private func stopsArraySortedByCode() -> [Stop] {
		return Array(stopsDict.values).sorted {
			Int($0.stopCode) ?? 0 < Int($1.stopCode) ?? 0
		}
    }
    
    /// Build search index, this func is call after stopsDict is populated
    private func buildSearchIndex() {
        
        // Populate array and control if is empty then is true exit
        let array = stopsArraySortedByCode()
        guard !array.isEmpty else { return }
        
		self.isSearchIndexing = true
        
        // Build in background index for searching
        Task {
            await searchIndex.build(from: array)
            await MainActor.run { self.isSearchIndexing = false }
        }
    }
    
    // MARK: - Manage GTFS
    
    /// Control if cached is expired
    private func isCacheExpired(cache: GTFSCache) -> Bool {
        return Calendar.current.dateComponents(
			[.day],
			from: cache.fetchedAt,
			to: Date()
		).day ?? 8 > self.cacheExpirationDays
    }

    /// Control exist cached data, if not exit then download new GTFS and load data
    func loadGTFSData(forceRefresh: Bool = false) async {
        
        // If exist cached data, set this on current values
        if !forceRefresh, let cache = loadProcessedDataFromCache(),
		   !isCacheExpired(cache: cache) {
			
            self.stopsDict = cache.stops
            self.isLoading = false
            
            return
        }
        
        // if gtfs is nil exit
		guard let url = Self.gtfsURL else { return }

        let remoteLastModified = try? await fetchRemoteLastModified(url: url)
        
        // Get data from URL
        if !forceRefresh,
           let meta   = loadCacheMeta(),
           let cached = loadProcessedDataFromCache(),
		   
           meta.remoteLastModified == remoteLastModified,
           FileManager.default.fileExists(atPath: processedDataURL.path,
                                          
        ) {
            self.stopsDict = cached.stops
            self.isLoading = false
            return
        }

        // Download and load new gtfs data
        await downloadAndProcessGTFS(remoteLastModified: remoteLastModified)
    }
    
    /// Download gtfs and process then
    private func downloadAndProcessGTFS(remoteLastModified: String?) async {
		guard let url = Self.gtfsURL else { return }
        
        do {
            // Set variable to load mode
            self.isLoading = true

            let (data, _) = try await URLSession.shared.data(from: url)
            try await processGTFSData(data: data)

            // Save cached data
            let meta = CacheMeta(
				fetchedAt: Date(),
				remoteLastModified: remoteLastModified
			)
            
			if !saveCacheMeta(meta) { throw CacheError.SaveFailed }
            
			self.isLoading = false
            
        } catch {
            // Control type error
            if let currentError = error as? CacheError {
                print("DEBUG: Save GTFS error: \(currentError)")
                
            } else {
                print("DEBUG: Error to manage download gtfs: \(error)")
            }
            
            // Remove all reference on error data
            try? FileManager.default.removeItem(at: processedDataURL)
            try? FileManager.default.removeItem(at: metaURL)
            
			self.isLoading = false
        }
    }
    
    /// Get last modified file
    private func fetchRemoteLastModified(url: URL) async throws -> String? {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        let (_, response) = try await URLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else { return nil }

        for (k, v) in http.allHeaderFields {
            if let key = k as? String, key.lowercased() == "last-modified" {
                return v as? String
            }
        }
        
        return nil
    }
    
    /// Load cache data if exist
    private func loadCacheMeta() -> CacheMeta? {
        // Control path exist else return
		guard FileManager.default.fileExists(atPath: self.metaURL.path) else {
			return nil
		}
        
        do {
            let data = try Data(contentsOf: metaURL)
            
            // Contro get data is not empty
            guard !data.isEmpty else {
				try? FileManager.default.removeItem(at: metaURL)
				return nil
			}
            
            return try JSONDecoder().decode(
				CacheMeta.self,
				from: data
			)
            
        } catch { // If occour one error remove data and return nil value
            try? FileManager.default.removeItem(at: metaURL)
            
            return nil
        }
    }
    
    /// Load Cache data
    private func loadProcessedDataFromCache() -> GTFSCache? {
        do {
            guard FileManager.default.fileExists(
				atPath: processedDataURL.path
			) else { return nil }
			
            let data = try Data(contentsOf: processedDataURL)
            
            guard !data.isEmpty else {
                try? FileManager.default.removeItem(at: processedDataURL)
                return nil
            }
            
            return try JSONDecoder().decode(
				GTFSCache.self,
				from: data
			)
            
        } catch {
            print("Error loading cache: \(error)")
            try? FileManager.default.removeItem(at: processedDataURL)
            try? FileManager.default.removeItem(at: metaURL)
            
            return nil
        }
    }

    /// Save new gtfs in cache
    private func saveCacheMeta(_ meta: CacheMeta) -> Bool {
        do {
            try FileManager.default.createDirectory(
				at: cacheDirectory,
				withIntermediateDirectories: true
			)
			
            let data = try JSONEncoder().encode(meta)
            try data.write(
				to: metaURL,
				options: .atomic
			)
            
            return true
            
        } catch { return false }
    }
    
    // MARK: - Manage CSV GTFS file
	
	/// Legge un CSV riga per riga senza caricarlo in memoria
	private func streamCSV(
		url: URL,
		onRow: (_ row: [String], _ header: [String]) -> Void
	) async throws {
		
		guard FileManager.default.fileExists(atPath: url.path) else { return }
		
		var header: [String]?
		var separator: Character = ","
		
		for try await line in url.resourceBytes.lines {
			let trimmed = line.trimmingCharacters(in: .whitespaces)
			if trimmed.isEmpty { continue }
			
			// Determina separatore e header dalla prima riga
			if header == nil {
				separator = trimmed.contains(";") ? ";" : ","
				header = splitCSVLine(trimmed, separator: separator)
				continue
			}
			
			// Processa righe successive
			let fields = splitCSVLine(trimmed, separator: separator)
			if let h = header {
				onRow(fields, h)
			}
		}
	}

	private func processGTFSData(data: Data) async throws {
		// 1. Estrazione ZIP
		try FileManager.default.createDirectory(
			at: cacheDirectory,
			withIntermediateDirectories: true
		)
		
		let zipURL = cacheDirectory.appendingPathComponent("gtt_gtfs.zip")
		try data.write(to: zipURL, options: .atomic)
		
		let extractDir = cacheDirectory.appendingPathComponent("gtfs_extract")
		if FileManager.default.fileExists(atPath: extractDir.path) {
			try FileManager.default.removeItem(at: extractDir)
		}
		
		try FileManager.default.createDirectory(
			at: extractDir,
			withIntermediateDirectories: true
		)
		
		try FileManager.default.unzipItem(at: zipURL, to: extractDir)
		
		// Path dei file
		let routesPath    = extractDir.appendingPathComponent("routes.txt")
		let tripsPath     = extractDir.appendingPathComponent("trips.txt")
		let stopTimesPath = extractDir.appendingPathComponent("stop_times.txt")
		let stopsAttrPath = extractDir.appendingPathComponent("stop_attributes.txt")
		let stopsPath     = extractDir.appendingPathComponent("stops.txt")

		// 2. Processamento Routes
		var routes: [String: RouteInfo] = [:]
		try await streamCSV(url: routesPath) { row, header in
			guard let idIdx = header.firstIndex(of: "route_id"),
				  let shortIdx = header.firstIndex(of: "route_short_name"),
				  let typeIdx = header.firstIndex(of: "route_type"),
				  row.count > max(idIdx, shortIdx, typeIdx) else { return }
			
			let type = Int(row[typeIdx]) ?? -1
			routes[row[idIdx]] = RouteInfo(
				shortName: row[shortIdx],
				type: TypeVehicle(rawValue: type) ?? .bus
			)
		}
		
		// 3. Processamento Trips
		var trips: [String: String] = [:] // TripID -> RouteID
		try await streamCSV(url: tripsPath) { row, header in
			guard let tidIdx = header.firstIndex(of: "trip_id"),
				  let ridIdx = header.firstIndex(of: "route_id"),
				  row.count > max(tidIdx, ridIdx) else { return }
			
			trips[row[tidIdx]] = row[ridIdx]
		}
		
		// 4. Processamento Stop Attributes
		var stopCityMap: [String: String] = [:]
		try await streamCSV(url: stopsAttrPath) { row, header in
			guard let sidIdx = header.firstIndex(of: "stop_id"),
				  let cityIdx = header.firstIndex(of: "stop_city"),
				  row.count > max(sidIdx, cityIdx) else { return }
			
			stopCityMap[row[sidIdx]] = row[cityIdx]
		}
		
		// 5. Processamento Stop Times (Il file più grande - Streaming fondamentale qui)
		var stopRoutes: [String: Set<RouteInfo>] = [:]
		try await streamCSV(url: stopTimesPath) { row, header in
			guard let tidIdx = header.firstIndex(of: "trip_id"),
				  let sidIdx = header.firstIndex(of: "stop_id"),
				  row.count > max(tidIdx, sidIdx) else { return }
			
			let tripId = row[tidIdx]
			let stopId = row[sidIdx]
			
			// Risoluzione inversa: Trip -> RouteID -> RouteInfo
			if let routeId = trips[tripId], let info = routes[routeId] {
				stopRoutes[stopId, default: []].insert(info)
			}
		}
		
		trips.removeAll()
		routes.removeAll()
		
		var newStopsDict: [String: Stop] = [:]
		try await streamCSV(url: stopsPath) { row, header in
			guard let idIdx = header.firstIndex(of: "stop_id"),
				  let codeIdx = header.firstIndex(of: "stop_code"),
				  let nameIdx = header.firstIndex(of: "stop_name"),
				  let latIdx = header.firstIndex(of: "stop_lat"),
				  let lonIdx = header.firstIndex(of: "stop_lon"),
				  row.count > max(idIdx, codeIdx, nameIdx, latIdx, lonIdx) else { return }
			
			let stopId = row[idIdx]
			let code = row[codeIdx]
			let rawName = row[nameIdx]
			let name = rawName.components(separatedBy: " - ").last ?? rawName
			let city = stopCityMap[stopId] ?? "Unknown"
			let routesForStop = stopRoutes[stopId] ?? []
			
			let stop = Stop(
				id: stopId,
				stopCode: code,
				stopName: name.capitalized,
				city: city,
				latitude: Double(row[latIdx]) ?? 0.0,
				longitude: Double(row[lonIdx]) ?? 0.0,
				routes: Array(routesForStop).sorted { $0.shortName > $1.shortName }
			)
			
			newStopsDict[code] = stop
		}
		
		let cache = GTFSCache(stops: newStopsDict, fetchedAt: Date())
		let encoder = JSONEncoder()
		let jsonData = try encoder.encode(cache)
		try jsonData.write(to: processedDataURL, options: .atomic)
		
		await MainActor.run {
			self.stopsDict = newStopsDict
		}

		try? FileManager.default.removeItem(at: zipURL)
		try? FileManager.default.removeItem(at: extractDir)
	}
    
    /// CSV parsing helpers for split lines
    private func splitCSVLine(
		_ line: String,
		separator: Character
	) -> [String] {
		
        var fields: [String] = []
        var cur = ""
        var inQuotes = false
        let chars = Array(line)
        
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            
            if ch == "\"" {
                if inQuotes && i + 1 < chars.count && chars[i + 1] == "\"" {
                    cur.append("\"")
                    i += 1
					
                } else { inQuotes.toggle() }
				
            } else if ch == separator && !inQuotes {
                fields.append(cur.trimmingCharacters(in: .whitespacesAndNewlines))
                cur = ""
                
            } else { cur.append(ch) }
            
            i += 1
        }
        
        fields.append(cur.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return fields
    }
    
    // MARK: - Manage Quad tree
    
    /// Build quadratic tree for manage stop on map
    private func buildQuadTree() {
        // Control stops dictionary is not empty
        guard !stopsDict.isEmpty else { return }
        
		var minLat = 90.0, maxLat = -90.0
		var minLng = 180.0, maxLng = -180.0
		
		for stop in stopsDict.values {
			if stop.latitude < minLat { minLat = stop.latitude }
			if stop.latitude > maxLat { maxLat = stop.latitude }
			if stop.longitude < minLng { minLng = stop.longitude }
			if stop.longitude > maxLng { maxLng = stop.longitude }
		}
        
		let tree = QuadTree<String>(
			bounds: BoundingBox(
				minLat: minLat,
				maxLat: maxLat,
				minLng: minLng,
				maxLng: maxLng
			)
		)
        
		for stop in stopsDict.values {
			let _ = tree.insert(
				coordinate: CLLocationCoordinate2D(
					latitude: stop.latitude,
					longitude: stop.longitude
				),
				value: stop.stopCode
			)
		}
        
        self.quadTree = tree
    }
}
