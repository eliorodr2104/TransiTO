//
//  ArrivalsViewmodel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI
internal import Combine

@MainActor
class ArrivalsViewmodel: ObservableObject {
    @Published var arrivals: [String: [Arrival]] = [:]
    @Published var favoriteStopsArrivals: [String: [Arrival]] = [:]
    
    @Published var lastFetchDate: Date? = nil
    @Published var errorMessage: String? = nil
    
    private static let graphQLEndpoint = "https://plan.muoversiatorino.it/otp/routers/mato/index/graphql"
    
    // MARK: - GraphQL Query
    private let stopQuery = """
        query ConsolidatedQuery($id: String!, $startTime: Long!, $timeRange: Int!, $numberOfDepartures: Int!) {
            stop(id: $id) {
                ... on Stop {
                    stops: stoptimesWithoutPatterns(
                        startTime: $startTime
                        timeRange: $timeRange
                        numberOfDepartures: $numberOfDepartures
                        omitCanceled: true
                    ) {
                        serviceDay
                        realtimeDeparture
                        realtime
                        trip {
                            tripHeadsign
                            wheelchairAccessible
                            occupancyStatus
                            pattern {
                                route {
                                    gtfsId
                                    shortName
                                }
                            }
                        }
                    }
                }
            }
        }
    """
    
    // MARK: - Public Methods
    func fetchStopArrivals(for stopId: String) async {
        errorMessage = nil
        arrivals = [:]
        
        do {
            let gqlData = try await performGraphQLQuery(stopId: stopId)
            let convertedArrivals = convertGraphQLToArrivals(gqlData)
            arrivals[stopId] = convertedArrivals
            
        } catch {
            errorMessage = "Error GraphQL: \(error.localizedDescription)"
            print(errorMessage!)
        }
    }
    
    private func fetchStopsArrivals(for stopId: String) async {
        errorMessage = nil
        
        do {
            let gqlData = try await performGraphQLQuery(stopId: stopId)
            let convertedArrivals = convertGraphQLToArrivals(gqlData)
            favoriteStopsArrivals[stopId] = convertedArrivals
            
        } catch {
            errorMessage = "Error GraphQL: \(error.localizedDescription)"
            print(errorMessage!)
        }
    }
    
    func fetchFavoriteStopArrivals(favoritesStops: [String], updateAvailable: Binding<Bool>) async {
        let now = Date()
        
        if let lastFetchDate, now.timeIntervalSince(lastFetchDate) < 1800 {
            return
        }
        
        updateAvailable.wrappedValue = true
        favoriteStopsArrivals = [:]
        
        for stop in favoritesStops {
            await fetchStopsArrivals(for: stop)
        }
        
        lastFetchDate = now
    }
    
    // MARK: - GraphQL Helper
    
    private func performGraphQLQuery(stopId: String) async throws -> [GraphQLStopTime] {
        guard let url = URL(string: Self.graphQLEndpoint) else {
            throw URLError(.badURL)
        }
        
        let variables: [String: Any] = [
            "id": "gtt:\(stopId)",
            "startTime": Int(Date().timeIntervalSince1970),
            "timeRange": 14400, // 12h range
            "numberOfDepartures": 15
        ]
        
        let body: [String: Any] = [
            "query": stopQuery,
            "variables": variables
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoded = try JSONDecoder().decode(GraphQLResponse.self, from: data)
        
        guard let stops = decoded.data.stop?.stops else {
            return []
        }
        
        return stops
    }
    
    // MARK: - Conversion
    
    private func convertGraphQLToArrivals(_ gqlArrivals: [GraphQLStopTime]) -> [Arrival] {
        var converted: [Arrival] = []
        
        for stop in gqlArrivals {
            let timestamp = Date(timeIntervalSince1970: TimeInterval(stop.serviceDay + stop.realtimeDeparture))
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let scheduleString = formatter.string(from: timestamp)
            
            let lineName = stop.trip.pattern.route.shortName
            
            let arrival = Arrival(
                line: lineName,
                schedule: scheduleString,
                realtime: stop.realtime,
                direction: stop.trip.tripHeadsign
            )
            converted.append(arrival)
        }
        
        return converted
    }
    
    // MARK: - Existing Methods (unchanged)
    
    func getLineArrivals(for nameStop: String, in line: String) -> [Arrival] {
        return arrivals[nameStop]?.filter { $0.line == line } ?? []
    }
    
    func getAvailableLines(for nameStop: String, in favoritesLine: [Line]) -> Int {
        let lineSet = Set(favoritesLine.map { $0.number })
        let arrivalsLine = Set(favoriteStopsArrivals[nameStop]?.map { $0.line } ?? [])
        
        return arrivalsLine.intersection(lineSet).count
    }
    
    func getTimeRemainingArrival(for nameStop: String, in line: String) -> Int? {
        let filtered = arrivals[nameStop]?.filter { $0.line == line } ?? []
        let calendar = Calendar.current
        let now = Date()

        let futureArrivals: [Date] = filtered.compactMap { arrival in
            let parts = arrival.schedule.split(separator: ":").map { Int($0) }
            guard parts.count >= 2,
                  let hour = parts[0],
                  let minute = parts[1] else { return nil }
            
            let second = (parts.count > 2) ? (parts[2] ?? 0) : 0

            var comps = calendar.dateComponents([.year, .month, .day], from: now)
            comps.hour = hour
            comps.minute = minute
            comps.second = second

            guard let dateToday = calendar.date(from: comps) else { return nil }
            return (dateToday < now) ? calendar.date(byAdding: .day, value: 1, to: dateToday) : dateToday
        }
        .sorted()

        guard let nextArrival = futureArrivals.first else { return nil }

        let interval = nextArrival.timeIntervalSince(now)
        if interval <= 0 { return 0 }

        return Int(ceil(interval / 60.0))
    }
}
