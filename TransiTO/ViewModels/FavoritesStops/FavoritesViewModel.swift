//
//  StorageFavoriteViewmodel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI
internal import Combine

class FavoritesViewModel: ObservableObject {

    @Published var favoriteslines: [String: [Line]] = [:]
    @Published var favoritesStops: [String] = []
    
    private static let jsonStorageFile = "favorites_stops.json"
    
    init() { load() }
    
    private var fileURL: URL {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.hylo.TransportApp")!
        
        return container.appendingPathComponent(Self.jsonStorageFile)
    }
    
    func load() {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            favoriteslines = [:]
            updateStops()
            save()
            
            return
        }
        
        do {
            let data       = try Data(contentsOf: fileURL)
            let decoded    = try JSONDecoder().decode([String: [Line]].self, from: data)
            favoriteslines = decoded
            
            updateStops()
            
        } catch {
            print("Error loading json: \(error)")
            favoriteslines = [:]
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(favoriteslines)
            try data.write(to: fileURL)
            
        } catch {
            print("Error saving json: \(error)")
            
        }
    }
    
    func addStop(to stopId: String) {
        if favoriteslines[stopId] == nil {
            favoriteslines[stopId] = []
            
            updateStops()
            save()
        }
    }
    
    // MARK: - Add line
    func addLine(to stopId: String, lineNumber: String, isPrefer: Bool = false) {
        let line = Line(number: lineNumber, isFocus: isPrefer)
        
        if favoriteslines[stopId] != nil {
            if !favoriteslines[stopId]!.contains(line) && isPrefer {
                
                favoriteslines[stopId] = favoriteslines[stopId]!.map { line in
                    var copy = line
                    copy.isFocus = false
                    
                    return copy
                }

            } else { favoriteslines[stopId]?.append(line) }
            
        } else { favoriteslines[stopId] = [line] }
        
        save()
    }
    
    func removeStop(from stopId: String) {
        favoriteslines.removeValue(forKey: stopId)
        
        updateStops()
        save()
    }
    
    // MARK: - Remove line
    func removeLine(from stopId: String, lineNumber: String) {
        favoriteslines[stopId]?.removeAll { $0.number == lineNumber }
        
        if favoriteslines[stopId]?.isEmpty == true {
            favoriteslines.removeValue(forKey: stopId)
        }
        
        save()
    }
    
    
    // MARK: - Set focus line
    func setFocusLine(stopId: String, lineNumber: String) {
        for (stop, var lines) in favoriteslines {
            
            for index in lines.indices {
                lines[index].isFocus = (stop == stopId && lines[index].number == lineNumber)
            }
            
            favoriteslines[stop] = lines
        }
        
        save()
    }
    
    func removeFocusLine(in stopId: String, for lineNumber: String) {
        guard var lineList = favoriteslines[stopId], let index = lineList.firstIndex(where: { $0.number == lineNumber }) else {
            return
        }
        
        lineList[index].isFocus = false
        favoriteslines[stopId] = lineList
        
        save()
    }

    
    // MARK: - Get lines
    func getLines(to stopId: String) -> [Line] {
        return favoriteslines[stopId] ?? []
    }
    
    // MARK: - Get single line
    func getLine(in stopId: String, for lineNumber: String) -> Line? {
        return favoriteslines[stopId]?.first(where: { $0.number == lineNumber })
    }
    
    // MARK: - Get focus line
    func getFocusLine(to stopId: String) -> Line? {
        return favoriteslines[stopId]?.first(where: { $0.isFocus })
    }
    
    // MARK: - Update id stops
    private func updateStops() {
        favoritesStops = Array(favoriteslines.keys)
            .sorted { Int($0)! < Int($1)! }
    }
}
