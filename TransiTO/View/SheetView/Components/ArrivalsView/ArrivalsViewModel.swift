//
//  ArrivalsViewmodel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI
internal import Combine

@MainActor
class ArrivalsViewModel: ObservableObject {
	
    @Published
	var arrivals: [String: [Arrival]] = [:]
	
    @Published
	var lastFetchDate: Date? = nil
	
    @Published
	var errorMessage: String? = nil
    
    private static let graphQLEndpoint = "https://plan.muoversiatorino.it/otp/routers/mato/index/graphql"
    
    /// GraphQL Query
    private static let stopQuery = """
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
        
        do {
            let gqlData = try await performGraphQLQuery(stopId)
            let convertedArrivals = convertGraphQLToArrivals(gqlData)
            arrivals[stopId] = convertedArrivals
            
        } catch {
            errorMessage = "Error GraphQL: \(error.localizedDescription)"
            print(errorMessage!)
        }
    }
    
    // MARK: - GraphQL Handlers
    
    private func performGraphQLQuery(_ stopId: String) async throws -> [GraphQLStopTime] {
		
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
			"query": Self.stopQuery,
            "variables": variables
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = requestData
		
        request.setValue(
			"application/json",
			forHTTPHeaderField: "Content-Type"
		)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoded = try JSONDecoder().decode(GraphQLResponse.self, from: data)
        
        guard let stops = decoded.data.stop?.stops else {
            return []
        }
        
        return stops
    }
        
    private func convertGraphQLToArrivals(
		_ gqlArrivals: [GraphQLStopTime]
	) -> [Arrival] {
		
        var converted: [Arrival] = []
        
        for stop in gqlArrivals {
            let timestamp = Date(
				timeIntervalSince1970: TimeInterval(
					stop.serviceDay + stop.realtimeDeparture
				)
			)
			
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
			
            let scheduleString = formatter.string(from: timestamp)
            let lineName = stop.trip.pattern.route.shortName
            
            let arrival = Arrival(
                line	 : lineName,
                schedule : scheduleString,
                realtime : stop.realtime,
                direction: stop.trip.tripHeadsign
            )
            
            converted.append(arrival)
        }
        
        return converted
    }
    
    
    func getLineArrivals(
		for nameStop: String,
		in  line	: String
		
	) -> [Arrival] {
		return arrivals[nameStop]?.filter { $0.line == line } ?? []
    }
	
	func getFirstArrival(
		in nameStop: String,
		_  line    : String
		
	) -> Arrival? {
		var arrival = self.arrivals[nameStop]?.first { $0.line == line }

		if let arr = arrival, let time = getMinutesRemaining(for: arr) {
			arrival?.remainingMinutes = time
		}
		
		return arrival
	}
    
	func getMinutesRemaining(for arrival: Arrival) -> Int? {
		let now = Date()
		let calendar = Calendar.current
		
		let scheduleString = arrival.schedule
			.replacingOccurrences(of: "\u{202F}", with: " ")
			.replacingOccurrences(of: "\u{00A0}", with: " ")
			.trimmingCharacters(in: .whitespacesAndNewlines)
		
		
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone.current
		
		let formatsToTry = [
			"h:mm:ss a",  // "4:08:34 PM"
			"h:mm a",     // "4:08 PM"
			"HH:mm:ss",   // "16:08:34"
			"HH:mm"       // "16:08"
		]
		
		var timeComponents: DateComponents?
		
		for format in formatsToTry {
			formatter.dateFormat = format
			if let date = formatter.date(from: scheduleString) {
				timeComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
				break
			}
		}
		
		guard let components = timeComponents,
			  let hour = components.hour,
			  let minute = components.minute else {
			print("Warning: Impossibile parsare l'orario: \(scheduleString)")
			return nil
		}
		
		var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
		targetComponents.hour = hour
		targetComponents.minute = minute
		targetComponents.second = components.second ?? 0
		
		guard let targetDateToday = calendar.date(from: targetComponents) else { return nil }
		
		let finalDate: Date
		if targetDateToday < now {
			finalDate = calendar.date(byAdding: .day, value: 1, to: targetDateToday) ?? targetDateToday
		} else {
			finalDate = targetDateToday
		}
		
		let interval = finalDate.timeIntervalSince(now)
		
		if interval <= 0 { return 0 }
		
		return Int(ceil(interval / 60.0))
	}
}
