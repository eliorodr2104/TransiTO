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
    
    /// Published stops information, this is dictionary for computational complexity O(1)
    @Published private(set) var stopsDict: [String: AllInfoStop] = [:]
    
    /// Quad tree for manage stops on map
    private(set) var quadTree: QuadTree<AllInfoStop>?
    
    /// Download and processing state
    @Published private(set) var isLoading      : Bool   = false
    
    
    /// State for search stop on UI
    @Published private(set) var searchResults   : [AllInfoStop] = []
    @Published              var searchQuery     : String        = ""
    @Published private      var isSearchIndexing: Bool          = false

    /// Config setup
    private let gtfsURL            : URL? = URL(string: "https://www.gtt.to.it/open_data/gtt_gtfs.zip") ?? nil
    private let cacheDirectory     : URL
    private let processedDataURL   : URL
    private let metaURL            : URL
    private let cacheExpirationDays: UInt8 = 7
    
    /// Seearch service
    private let searchIndex = StopsSearchIndexService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constructor View model
    init() {
        // Get cache data if exist
        self.cacheDirectory   = FileManager
                                    .default
                                    .temporaryDirectory
                                    .appendingPathComponent("GTT_GTFS")
        self.processedDataURL = cacheDirectory
                                    .appendingPathComponent("gtfs_cache.json")
        self.metaURL          = cacheDirectory
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
                let currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if currentQuery.isEmpty { self.searchResults = []; return }
                
                // launch Task to call async search
                Task { [weak self] in
                    guard let self = self else { return }
                    
                    let results        = await self.searchIndex.search(currentQuery, maxResults: 100)
                    self.searchResults = results
                }

            }
            .store(in: &cancellables) // Store value in cancellables
        
        
        // Load data or update
        Task { await loadGTFSData()
            
            buildQuadTree()
            buildSearchIndex()
        }
    }
    
    // MARK: - Searching Func's
    
    /// Helper to get sorted array of stops when needed
    private func stopsArraySortedByCode() -> [AllInfoStop] {
        return Array(stopsDict.values) .sorted { Int($0.stopCode) ?? 0 < Int($1.stopCode) ?? 0 }
    }
    
    /// Build search index, this func is call after stopsDict is populated
    private func buildSearchIndex() {
        
        // Populate array and control if is empty then is true exit
        let array = stopsArraySortedByCode()
        guard !array.isEmpty else { return }
        
        isSearchIndexing = true
        
        // Build in background index for searching
        Task {
            await searchIndex.build(from: array)
            await MainActor.run { self.isSearchIndexing = false }
        }
    }
    
    // MARK: - Manage GTFS
    
    /// Control if cached is expired
    private func isCacheExpired(cache: GTFSCache) -> Bool {
        return Calendar.current.dateComponents([.day], from: cache.fetchedAt, to: Date()).day ?? 8 > self.cacheExpirationDays
    }

    /// Control exist cached data, if not exit then download new GTFS and load data
    func loadGTFSData(forceRefresh: Bool = false) async {
        
        // If exist cached data, set this on current values
        if !forceRefresh, let cache = loadProcessedDataFromCache(), !isCacheExpired(cache: cache) {
            self.stopsDict = cache.stops
            self.isLoading = false
            
            return // Exit program
        }
        
        // if gtfs is nil exit
        guard let url = gtfsURL else { return }

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
        guard let url = gtfsURL else { return }
        
        do {
            // Set variable to load mode
            self.isLoading = true

            let (data, _) = try await URLSession.shared.data(from: url)
            try await processGTFSData(data: data)

            // Save cached data
            let meta = CacheMeta(fetchedAt: Date(), remoteLastModified: remoteLastModified)
            if !saveCacheMeta(meta) {
                throw CacheError.SaveFailed
            }
            
            isLoading = false
            
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
            
            isLoading = false
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
        guard FileManager.default.fileExists(atPath: self.metaURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: metaURL)
            
            // Contro get data is not empty
            guard !data.isEmpty else { try? FileManager.default.removeItem(at: metaURL); return nil }
            
            return try JSONDecoder().decode(CacheMeta.self, from: data)
            
        } catch { // If occour one error remove data and return nil value
            try? FileManager.default.removeItem(at: metaURL)
            
            return nil
        }
    }
    
    /// Load Cache data
    private func loadProcessedDataFromCache() -> GTFSCache? {
        do {
            guard FileManager.default.fileExists(atPath: processedDataURL.path) else { return nil }
            let data = try Data(contentsOf: processedDataURL)
            
            guard !data.isEmpty else {
                try? FileManager.default.removeItem(at: processedDataURL)
                return nil
            }
            
            return try JSONDecoder().decode(GTFSCache.self, from: data)
            
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
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(meta)
            try data.write(to: metaURL, options: .atomic)
            
            return true
            
        } catch { return false }
    }
    
    // MARK: - Manage CSV GTFS file
    
    /// Read GTFS file
    private func readCSV(file: URL) throws -> [[String]] {
        
        // Control file exist on device, else return error
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw NSError(
                domain: "GTFS",
                code: 10,
                userInfo: [NSLocalizedDescriptionKey: "File not found: \(file.lastPathComponent)"]
            )
        }
        
        // Set content CSV
        let content  = try String(contentsOf: file, encoding: .utf8)
        let rawLines = content.components(separatedBy: .newlines)
        let lines    = rawLines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // If line not exist return empty value
        guard let first = lines.first else { return [] }
        
        let separator: Character = first.contains(";") ? ";" : ","
        
        return lines.map { splitCSVLine($0, separator: separator) }
    }

    /// Process GTFS files
    private func processGTFSData(data: Data) async throws {
        // Create temp dir for extraction zip
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Extract zip data
        let zipURL = cacheDirectory.appendingPathComponent("gtt_gtfs.zip")
        try data.write(to: zipURL, options: .atomic)
        let extractDir = cacheDirectory.appendingPathComponent("gtfs_extract")
        
        // Contro extract dir exist then delete old data
        if FileManager.default.fileExists(atPath: extractDir.path) {
            try FileManager.default.removeItem(at: extractDir)
        }
        
        // Create new cached data
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: zipURL, to: extractDir)


        // Set CSV paths
        let stopsPath     = extractDir.appendingPathComponent("stops.txt")
        let routesPath    = extractDir.appendingPathComponent("routes.txt")
        let tripsPath     = extractDir.appendingPathComponent("trips.txt")
        let stopTimesPath = extractDir.appendingPathComponent("stop_times.txt")
        let stopsAttrPath = extractDir.appendingPathComponent("stop_attributes.txt")

        // Read CSV
        let stopsCSV     = try readCSV(file: stopsPath)
        let routesCSV    = try readCSV(file: routesPath)
        let tripsCSV     = try readCSV(file: tripsPath)
        let stopTimesCSV = try readCSV(file: stopTimesPath)
        let stopsAttrCSV = try readCSV(file: stopsAttrPath)

        /// Get index header
        func getHeaderIndex(_ column: String, header: [String]) throws -> Int {
            guard let i = header.firstIndex(of: column) else {
                throw NSError(domain: "GTFS", code: 1, userInfo: [NSLocalizedDescriptionKey: "Column \(column) not found"])
            }
            
            return i
        }

        // Get headers
        let stopsHeader     = stopsCSV.first!
        let routesHeader    = routesCSV.first!
        let tripsHeader     = tripsCSV.first!
        let stopTimesHeader = stopTimesCSV.first!
        let stopsAttrHeader = stopsAttrCSV.first!

        // Get index for header
        let stopIdIndex          = try getHeaderIndex("stop_id",           header: stopsHeader)
        let stopCodeIndex        = try getHeaderIndex("stop_code",         header: stopsHeader)
        let stopNameIndex        = try getHeaderIndex("stop_name",         header: stopsHeader)
        let stopLatIndex         = try getHeaderIndex("stop_lat",          header: stopsHeader)
        let stopLonIndex         = try getHeaderIndex("stop_lon",          header: stopsHeader)

        let routeIdIndex         = try getHeaderIndex("route_id",         header: routesHeader)
        let routeShortIndex      = try getHeaderIndex("route_short_name", header: routesHeader)
        let routeTypeIndex       = try getHeaderIndex("route_type",       header: routesHeader)

        let tripIdIndex          = try getHeaderIndex("trip_id",          header: tripsHeader)
        let tripRouteIdIndex     = try getHeaderIndex("route_id",         header: tripsHeader)

        let stopTimesTripIdIndex = try getHeaderIndex("trip_id",          header: stopTimesHeader)
        let stopTimesStopIdIndex = try getHeaderIndex("stop_id",          header: stopTimesHeader)

        let stopAttrIdIndex      = try getHeaderIndex("stop_id",          header: stopsAttrHeader)
        let stopAttrCityIndex    = try getHeaderIndex("stop_city",        header: stopsAttrHeader)

        // Parse all routes
        var routes: [String: RouteInfo] = [:]
        for row in routesCSV.dropFirst() {
            if row.count > max(routeIdIndex, routeShortIndex, routeTypeIndex) {
                let id     = row[routeIdIndex]
                let short  = row[routeShortIndex]
                let type   = Int(row[routeTypeIndex]) ?? -1
                
                routes[id] = RouteInfo(shortName: short, type: type)
            }
        }
        
        // Parse all trips
        var trips: [String: String] = [:]
        
        for row in tripsCSV.dropFirst() {
            if row.count > max(tripIdIndex, tripRouteIdIndex) {
                trips[row[tripIdIndex]] = row[tripRouteIdIndex]
                
            }
        }

        // Parse all stops_attributes
        var stopCityMap: [String: String] = [:]
        
        for row in stopsAttrCSV.dropFirst() {
            if row.count > max(stopAttrIdIndex, stopAttrCityIndex) {
                stopCityMap[row[stopAttrIdIndex]] = row[stopAttrCityIndex]
                
            }
        }

        // Map stopId -> set of routes
        var stopRoutes: [String: Set<RouteInfo>] = [:]
        for row in stopTimesCSV.dropFirst() {
            if row.count > max(stopTimesTripIdIndex, stopTimesStopIdIndex) {
                let tid = row[stopTimesTripIdIndex]
                let sid = row[stopTimesStopIdIndex]
                
                if let rid = trips[tid], let routeInfo = routes[rid] {
                    stopRoutes[sid, default: []].insert(routeInfo)
                }
                
            }
        }

        // build stops dictionary and use stopCode with key
        var stopsDict: [String: AllInfoStop] = [:]
        
        for row in stopsCSV.dropFirst() {
            
            if row.count > max(stopIdIndex, stopCodeIndex, stopNameIndex, stopLatIndex, stopLonIndex) {
                let sid = row[stopIdIndex]
                let code = row[stopCodeIndex]
                let name = row[stopNameIndex]
                let lat = Double(row[stopLatIndex]) ?? 0.0
                let lon = Double(row[stopLonIndex]) ?? 0.0
                let city = stopCityMap[sid] ?? "Unknown"
                let routesForStop = stopRoutes[sid] ?? []

                let stop = AllInfoStop(
                    stopId: sid,
                    stopCode: code,
                    stopName: name,
                    city: city,
                    latitude: lat,
                    longitude: lon,
                    routes: Array(routesForStop).sorted { $0.shortName > $1.shortName }
                )
                
                // Use stopCode with key
                stopsDict[code] = stop
            }
        }
        
        // save cache
        let cache   = GTFSCache(stops: stopsDict, fetchedAt: Date())
        let encoder = JSONEncoder()
        
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(cache)
        try jsonData.write(to: processedDataURL, options: .atomic)

        self.stopsDict = stopsDict

        // Remove temp cached data
        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: extractDir)
    }
    
    /// CSV parsing helpers for split lines
    private func splitCSVLine(_ line: String, separator: Character) -> [String] {
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
                } else {
                    inQuotes.toggle()
                }
            } else if ch == separator && !inQuotes {
                fields.append(cur.trimmingCharacters(in: .whitespacesAndNewlines))
                cur = ""
                
            } else {
                cur.append(ch)
            }
            
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
        
        let allStops = Array(stopsDict.values) // TODO, CHANGE THIS, BECAUSE CONVERT DICT TO ARRAY IN TWO PART OF CODE
        
        // Calcule one time lat and long
        var minLat = allStops[0].latitude
        var maxLat = allStops[0].latitude
        var minLng = allStops[0].longitude
        var maxLng = allStops[0].longitude
        
        // Iterate one time the list and create values for the Bounding Box
        for stop in allStops {
            if stop.latitude  < minLat { minLat = stop.latitude }
            if stop.latitude  > maxLat { maxLat = stop.latitude }
            if stop.longitude < minLng { minLng = stop.longitude }
            if stop.longitude > maxLng { maxLng = stop.longitude }
        }
        
        let tree = QuadTree<AllInfoStop>(
            bounds: BoundingBox(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng)
        )
        
        for stop in allStops {
            let _ = tree.insert(
                coordinate: CLLocationCoordinate2D(
                    latitude: stop.latitude,
                    longitude: stop.longitude
                ),
                value: stop
            )
        }
        
        self.quadTree = tree
    }
}
