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
    
    // Published original data
    @Published private(set) var stopsDict: [String: AllInfoStop] = [:]
    
    // Quad tree
    var quadTree: QuadTree<AllInfoStop>?
    
    // download / processing state
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    
    // search for UI
    @Published var searchQuery     : String        = ""
    @Published var searchResults   : [AllInfoStop] = []
    @Published var isSearchIndexing: Bool          = false

    // config
    private let gtfsURL = URL(string: "https://www.gtt.to.it/open_data/gtt_gtfs.zip")!
    private let cacheDirectory: URL
    private let processedDataURL: URL
    private let metaURL: URL
    private let cacheExpirationDays = 7
    
    // search service
    private let searchIndex = StopsSearchIndexService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Cache meta
    struct CacheMeta: Codable {
        let fetchedAt: Date
        let remoteLastModified: String?
    }
    
    // MARK: - Init
    init() {
        self.cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("GTT_GTFS")
        self.processedDataURL = cacheDirectory.appendingPathComponent("gtfs_cache.json")
        self.metaURL = cacheDirectory.appendingPathComponent("gtfs_cache_meta.json")
        self.isLoading = true
        
        $searchQuery
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if q.isEmpty {
                    self.searchResults = []
                    return
                }
                
                // launch Task to call async search (keeps UI responsive)
                Task {
                    let results = await self.searchIndex.search(q, maxResults: 100)
                    await MainActor.run {
                        self.searchResults = results
                    }
                }
            }
            .store(in: &cancellables)
        
        
        Task {
            await loadGTFSData()
            buildQuadTree()
            buildSearchIndex()
        }
    }
    
    // MARK: - Helper to get sorted array of stops when needed (non-public)
    private func stopsArraySortedByCode() -> [AllInfoStop] {
        return Array(stopsDict.values)
            .sorted { Int($0.stopCode) ?? 0 < Int($1.stopCode) ?? 0 }
        
    }

    // MARK: - Build search index (call after stopsDict is populated)
    private func buildSearchIndex() {
        let array = stopsArraySortedByCode()
        guard !array.isEmpty else { return }
        
        isSearchIndexing = true
        
        Task {
            await searchIndex.build(from: array)
            await MainActor.run {
                self.isSearchIndexing = false
            }
            
        }
    }

    // MARK: - Public load
    func loadGTFSData(forceRefresh: Bool = false) async {
        loadingProgress = 0.05

        if !forceRefresh, let cache = loadProcessedDataFromCache(), !isCacheExpired(cache: cache) {
            self.stopsDict = cache.stops
            loadingProgress = 1.0
            isLoading = false
            return
        }

        let remoteLM = try? await fetchRemoteLastModified(url: gtfsURL)
        if !forceRefresh, let meta = loadCacheMeta(), meta.remoteLastModified == remoteLM,
           FileManager.default.fileExists(atPath: processedDataURL.path) {
            if let cached = loadProcessedDataFromCache() {
                self.stopsDict = cached.stops
                loadingProgress = 1.0
                isLoading = false
                return
            }
        }

        await downloadAndProcessGTFS(remoteLastModified: remoteLM)
    }
    
    private func buildQuadTree() {
        guard !stopsDict.isEmpty else { return }
        
        let allStops = Array(stopsDict.values)
        // bbox globale (puoi ottimizzare con min/max reali delle fermate)
        let bbox = BoundingBox(minLat: allStops.map{$0.latitude}.min() ?? 0,
                               maxLat: allStops.map{$0.latitude}.max() ?? 0,
                               minLng: allStops.map{$0.longitude}.min() ?? 0,
                               maxLng: allStops.map{$0.longitude}.max() ?? 0)
        let tree = QuadTree<AllInfoStop>(bounds: bbox)
        
        for stop in allStops {
            let _ = tree.insert(coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude), value: stop)
        }
        
        self.quadTree = tree
    }

    // MARK: - Remote HEAD
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

    private func loadCacheMeta() -> CacheMeta? {
        guard FileManager.default.fileExists(atPath: metaURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: metaURL)
            guard !data.isEmpty else { try? FileManager.default.removeItem(at: metaURL); return nil }
            return try JSONDecoder().decode(CacheMeta.self, from: data)
            
        } catch {
            try? FileManager.default.removeItem(at: metaURL)
            return nil
            
        }
    }

    private func saveCacheMeta(_ meta: CacheMeta) {
        do {
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(meta)
            try data.write(to: metaURL, options: .atomic)
            
        } catch { }
    }

    private func isCacheExpired(cache: GTFSCache) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: cache.fetchedAt, to: Date()).day ?? 999
        
        return days > cacheExpirationDays
    }

    // MARK: - Download + process
    private func downloadAndProcessGTFS(remoteLastModified: String?) async {
        do {
            isLoading = true
            loadingProgress = 0.1
            let (data, _) = try await URLSession.shared.data(from: gtfsURL)
            loadingProgress = 0.3
            try await processGTFSData(data: data)

            let meta = CacheMeta(fetchedAt: Date(), remoteLastModified: remoteLastModified)
            saveCacheMeta(meta)

            loadingProgress = 1.0
            isLoading = false
        } catch {
            print("Error downloading/processing GTFS: \(error)")
            try? FileManager.default.removeItem(at: processedDataURL)
            try? FileManager.default.removeItem(at: metaURL)
            isLoading = false
            loadingProgress = 0.0
        }
    }

    // MARK: - CSV parsing helpers
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
                    cur.append("\""); i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if ch == separator && !inQuotes {
                fields.append(cur); cur = ""
            } else {
                cur.append(ch)
            }
            i += 1
        }
        fields.append(cur)
        return fields.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func readCSV(file: URL) throws -> [[String]] {
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw NSError(domain: "GTFS", code: 10, userInfo: [NSLocalizedDescriptionKey: "File not found: \(file.lastPathComponent)"])
        }
        let content = try String(contentsOf: file, encoding: .utf8)
        let rawLines = content.components(separatedBy: .newlines)
        let lines = rawLines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let first = lines.first else { return [] }
        let separator: Character = first.contains(";") ? ";" : ","
        return lines.map { splitCSVLine($0, separator: separator) }
    }

    // MARK: - Process GTFS (main)
    private func processGTFSData(data: Data) async throws {
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let zipURL = cacheDirectory.appendingPathComponent("gtt_gtfs.zip")
        try data.write(to: zipURL, options: .atomic)

        let extractDir = cacheDirectory.appendingPathComponent("gtfs_extract")
        if FileManager.default.fileExists(atPath: extractDir.path) {
            try FileManager.default.removeItem(at: extractDir)
        }
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: zipURL, to: extractDir)

        loadingProgress = 0.55

        // paths
        let stopsPath = extractDir.appendingPathComponent("stops.txt")
        let routesPath = extractDir.appendingPathComponent("routes.txt")
        let tripsPath = extractDir.appendingPathComponent("trips.txt")
        let stopTimesPath = extractDir.appendingPathComponent("stop_times.txt")
        let stopsAttrPath = extractDir.appendingPathComponent("stop_attributes.txt")

        // read csv
        let stopsCSV = try readCSV(file: stopsPath)
        let routesCSV = try readCSV(file: routesPath)
        let tripsCSV = try readCSV(file: tripsPath)
        let stopTimesCSV = try readCSV(file: stopTimesPath)
        let stopsAttrCSV = try readCSV(file: stopsAttrPath)
        loadingProgress = 0.7

        func idx(_ col: String, header: [String]) throws -> Int {
            guard let i = header.firstIndex(of: col) else {
                throw NSError(domain: "GTFS", code: 1, userInfo: [NSLocalizedDescriptionKey: "Column \(col) not found"])
            }
            return i
        }

        // headers
        let stopsHeader = stopsCSV.first!
        let routesHeader = routesCSV.first!
        let tripsHeader = tripsCSV.first!
        let stopTimesHeader = stopTimesCSV.first!
        let stopsAttrHeader = stopsAttrCSV.first!

        let stopIdIndex = try idx("stop_id", header: stopsHeader)
        let stopCodeIndex = try idx("stop_code", header: stopsHeader)
        let stopNameIndex = try idx("stop_name", header: stopsHeader)
        let stopLatIndex = try idx("stop_lat", header: stopsHeader)
        let stopLonIndex = try idx("stop_lon", header: stopsHeader)

        let routeIdIndex = try idx("route_id", header: routesHeader)
        let routeShortIndex = try idx("route_short_name", header: routesHeader)

        let tripIdIndex = try idx("trip_id", header: tripsHeader)
        let tripRouteIdIndex = try idx("route_id", header: tripsHeader)

        let stopTimesTripIdIndex = try idx("trip_id", header: stopTimesHeader)
        let stopTimesStopIdIndex = try idx("stop_id", header: stopTimesHeader)

        let stopAttrIdIndex = try idx("stop_id", header: stopsAttrHeader)
        let stopAttrCityIndex = try idx("stop_city", header: stopsAttrHeader)

        // parse routes
        var routes: [String: String] = [:] // routeId -> shortName
        for row in routesCSV.dropFirst() {
            if row.count > max(routeIdIndex, routeShortIndex) {
                let id = row[routeIdIndex]
                let short = row[routeShortIndex]
                routes[id] = short
            }
        }

        // parse trips
        var trips: [String: String] = [:] // tripId -> routeId
        for row in tripsCSV.dropFirst() {
            if row.count > max(tripIdIndex, tripRouteIdIndex) {
                trips[row[tripIdIndex]] = row[tripRouteIdIndex]
            }
        }

        // parse stops_attributes
        var stopCityMap: [String: String] = [:]
        for row in stopsAttrCSV.dropFirst() {
            if row.count > max(stopAttrIdIndex, stopAttrCityIndex) {
                stopCityMap[row[stopAttrIdIndex]] = row[stopAttrCityIndex]
            }
        }

        // map stopId -> set of routes
        var stopRoutes: [String: Set<String>] = [:]
        for row in stopTimesCSV.dropFirst() {
            if row.count > max(stopTimesTripIdIndex, stopTimesStopIdIndex) {
                let tid = row[stopTimesTripIdIndex]
                let sid = row[stopTimesStopIdIndex]
                if let rid = trips[tid], let rshort = routes[rid] {
                    stopRoutes[sid, default: []].insert(rshort)
                }
            }
        }

        // build stops dictionary - usando stopCode come chiave
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
                    routes: Array(routesForStop).sorted()
                )
                
                // Usa stopCode come chiave invece di stopId
                stopsDict[code] = stop
            }
        }
        
        // save cache
        let cache = GTFSCache(stops: stopsDict, fetchedAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(cache)
        try jsonData.write(to: processedDataURL, options: .atomic)

        self.stopsDict = stopsDict

        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: extractDir)
    }

    // MARK: - Cache load
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
}
