//
//  StorageFavoriteViewmodel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI
internal import Combine

class StorageFavoriteViewmodel: ObservableObject {

    @Published var favoritesTransportStop: [String: [Line]] = [:]
    @Published var stopStations: [String] = []
    
    private static let jsonStorageFile = "favorite_stops.json"
    
    init() {
        load()
    }
    
    private var fileURL: URL {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.hylo.TransportApp")!
        return container.appendingPathComponent(Self.jsonStorageFile)
    }
    
    func load() {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            favoritesTransportStop = [:]
            updateStops()
            save()
            
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: [Line]].self, from: data)
            favoritesTransportStop = decoded
            updateStops()
            
        } catch {
            print("Error loading json: \(error)")
            favoritesTransportStop = [:]
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(favoritesTransportStop)
            try data.write(to: fileURL)
            
        } catch {
            print("Error saving json: \(error)")
        }
    }
    
    func addStop(to stopId: String) {
        if favoritesTransportStop[stopId] == nil {
            favoritesTransportStop[stopId] = []
            
            updateStops()
            save()
        }
    }
    
    // MARK: - Add line
    func addLine(to stopId: String, lineNumber: String, isPrefer: Bool = false) {
        let line = Line(number: lineNumber, isFocus: isPrefer)
        
        if favoritesTransportStop[stopId] != nil {
            if !favoritesTransportStop[stopId]!.contains(line) {

                if isPrefer {
                    favoritesTransportStop[stopId] = favoritesTransportStop[stopId]!.map { l in
                        var copy = l
                        copy.isFocus = false
                        
                        return copy
                    }
                }
                favoritesTransportStop[stopId]?.append(line)
                save()
            }
        } else {
            favoritesTransportStop[stopId] = [line]
            save()
        }
    }
    
    func removeStop(from stopId: String) {
        favoritesTransportStop.removeValue(forKey: stopId)
        
        updateStops()
        save()
    }
    
    // MARK: - Remove line
    func removeLine(from stopId: String, lineNumber: String) {
        favoritesTransportStop[stopId]?.removeAll { $0.number == lineNumber }
        if favoritesTransportStop[stopId]?.isEmpty == true {
            favoritesTransportStop.removeValue(forKey: stopId)
        }
        save()
    }
    
    
    // MARK: - Set focus line
    func setFocusLine(stopId: String, lineNumber: String) {
        for (stop, var lines) in favoritesTransportStop {
            
            for index in lines.indices {
                lines[index].isFocus = (stop == stopId && lines[index].number == lineNumber)
            }
            
            favoritesTransportStop[stop] = lines
        }
        
        save()
    }
    
    func removeFocusLine(in stopId: String, for lineNumber: String) {
        guard var lineList = favoritesTransportStop[stopId], let index = lineList.firstIndex(where: { $0.number == lineNumber }) else {
            return
        }
        
        lineList[index].isFocus = false
        favoritesTransportStop[stopId] = lineList
        
        save()
    }

    
    // MARK: - Get lines
    func getLines(to stopId: String) -> [Line] {
        return favoritesTransportStop[stopId] ?? []
    }
    
    // MARK: - Get single line
    func getLine(in stopId: String, for lineNumber: String) -> Line? {
        return favoritesTransportStop[stopId]?.first(where: { $0.number == lineNumber })
    }
    
    // MARK: - Get focus line
    func getFocusLine(to stopId: String) -> Line? {
        return favoritesTransportStop[stopId]?.first(where: { $0.isFocus })
    }
    
    // MARK: - Update id stops
    private func updateStops() {
        stopStations = Array(favoritesTransportStop.keys)
            .sorted { Int($0)! < Int($1)! }
    }
}
