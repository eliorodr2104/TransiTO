//
//  GTFSViewModel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 12/09/25.
//

import Foundation
internal import Combine
import ZIPFoundation

// MARK: - GTFS ViewModel
@MainActor
class TransportStopsViewModel: ObservableObject {
    @Published private(set) var busStops: [String: BusStop] = [:]

    init() {
        loadFromBundle()
    }

    func getBusStop(byCode stopCode: String) -> BusStop? {
        busStops[stopCode]
    }

    func getRoutesForStop(stopCode: String) -> [String] {
        busStops[stopCode]?.routes ?? []
    }
    
    func loadFromBundle() {
        guard let url = Bundle.main.url(forResource: "database_stops_turin", withExtension: "json") else {
            print("File not found")
            
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: BusStop].self, from: data)
            self.busStops = decoded
            
        } catch {
            print("Error to load json file")
        }
    }

}
