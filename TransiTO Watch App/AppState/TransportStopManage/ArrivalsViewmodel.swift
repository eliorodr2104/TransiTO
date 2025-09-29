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
    
    private static let baseUrl = "https://www.gtt.to.it/cms/en/"
        
    func fetchStopArrivals(for stopId: String) async {
        errorMessage = nil
        arrivals = [:]
        
        var urlComponents = URLComponents(string: Self.baseUrl)
        urlComponents?.queryItems = [
            URLQueryItem(name: "option", value: "com_gtt"),
            URLQueryItem(name: "task", value: "palina.getTransitiOld"),
            URLQueryItem(name: "palina", value: stopId),
            URLQueryItem(name: "realtime", value: "true"),
            URLQueryItem(name: "get_param", value: "value")
        ]
        
        guard let url = urlComponents?.url else {
            errorMessage = "URL non valido"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Decodifica la risposta API nel formato ApiArrival
            let apiArrivals = try JSONDecoder().decode([ApiArrival].self, from: data)
            
            // Converte ApiArrival in Arrival mantenendo la struttura esistente
            let convertedArrivals = convertApiArrivalsToArrivals(apiArrivals)
            
            arrivals[stopId] = convertedArrivals
            
        } catch {
            errorMessage = "Errore di rete o parsing JSON: \(error.localizedDescription)"
            print(errorMessage!)
        }        
    }
    
    private func fetchStopsArrivals(for stopId: String) async {
        errorMessage = nil
        
        var urlComponents = URLComponents(string: Self.baseUrl)
        urlComponents?.queryItems = [
            URLQueryItem(name: "option", value: "com_gtt"),
            URLQueryItem(name: "task", value: "palina.getTransitiOld"),
            URLQueryItem(name: "palina", value: stopId),
            URLQueryItem(name: "realtime", value: "true"),
            URLQueryItem(name: "get_param", value: "value")
        ]
        
        guard let url = urlComponents?.url else {
            errorMessage = "URL non valido"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Decodifica la risposta API nel formato ApiArrival
            let apiArrivals = try JSONDecoder().decode([ApiArrival].self, from: data)
            
            // Converte ApiArrival in Arrival mantenendo la struttura esistente
            let convertedArrivals = convertApiArrivalsToArrivals(apiArrivals)
            
            favoriteStopsArrivals[stopId] = convertedArrivals
            
        } catch {
            errorMessage = "Errore di rete o parsing JSON: \(error.localizedDescription)"
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
    
    // MARK: - Private Methods
    
    private func convertApiArrivalsToArrivals(_ apiArrivals: [ApiArrival]) -> [Arrival] {
        var convertedArrivals: [Arrival] = []
        
        for apiArrival in apiArrivals {
            let arrivals = apiArrival.allArrivals
            let hasRealtime = !apiArrival.realtimeArrivals.isEmpty
            
            for arrivalTime in arrivals {
                let arrival = Arrival(
                    line: apiArrival.line,
                    schedule: arrivalTime,
                    realtime: hasRealtime
                )
                convertedArrivals.append(arrival)
            }
        }
        
        return convertedArrivals
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
