//
//  StorageFavoriteViewmodel.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI
internal import Combine

class FavoritesViewModel: ObservableObject {

    @Published var favoriteslines: [String: InfoStop] = [:]
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
            let decoded    = try JSONDecoder().decode([String: InfoStop].self, from: data)
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
    
    func addStop(to stopId: String, info infoStop: InfoStop) {
        if favoriteslines[stopId] == nil {
            favoriteslines[stopId] = infoStop
            
            updateStops()
            save()
        }
    }
    
    // MARK: - Add line
    func addLine(to stopId: String, lineNumber: String, isPrefer: Bool = false) {
        let newLine = Line(number: lineNumber, isFocus: isPrefer)
        
        guard var info = favoriteslines[stopId] else {
            // Stop must exist to add a line (coordinates are required to create InfoStop)
            return
        }
        
        if let existingIndex = info.lines.firstIndex(where: { $0.number == lineNumber }), isPrefer {
            
            // Line already exists; update focus if requested
            for idx in info.lines.indices {
                info.lines[idx].isFocus = (idx == existingIndex)
            }
            
        } else if isPrefer {
            
            // Line does not exist; clear focus if adding as preferred, then append
            for idx in info.lines.indices {
                info.lines[idx].isFocus = false
            }
            
            info.lines.append(newLine)
        }
        
        favoriteslines[stopId] = info
        save()
    }
    
    func removeStop(from stopId: String) {
        favoriteslines.removeValue(forKey: stopId)
        
        updateStops()
        save()
    }
    
    // MARK: - Remove line
    func removeLine(from stopId: String, lineNumber: String) {
        guard var info = favoriteslines[stopId] else { return }
        
        info.lines.removeAll { $0.number == lineNumber }
        
        if info.lines.isEmpty {
            favoriteslines.removeValue(forKey: stopId)
        } else {
            favoriteslines[stopId] = info
        }
        
        save()
    }
    
    
    // MARK: - Set focus line
    func setFocusLine(stopId: String, lineNumber: String) {
        for (stop, var info) in favoriteslines {
            for index in info.lines.indices {
                info.lines[index].isFocus = (stop == stopId && info.lines[index].number == lineNumber)
            }
            favoriteslines[stop] = info
        }
        
        save()
    }
    
    func removeFocusLine(in stopId: String, for lineNumber: String) {
        guard var info = favoriteslines[stopId],
              let index = info.lines.firstIndex(where: { $0.number == lineNumber }) else {
            return
        }
        
        info.lines[index].isFocus = false
        favoriteslines[stopId] = info
        
        save()
    }

    
    // MARK: - Get lines
    func getLines(to stopId: String) -> [Line] {
        return favoriteslines[stopId]?.lines ?? []
    }
    
    // MARK: - Get single line
    func getLine(in stopId: String, for lineNumber: String) -> Line? {
        return favoriteslines[stopId]?.lines.first(where: { $0.number == lineNumber })
    }
    
    // MARK: - Get focus line
    func getFocusLine(to stopId: String) -> Line? {
        return favoriteslines[stopId]?.lines.first(where: { $0.isFocus })
    }
    
    // MARK: - Update id stops
    private func updateStops() {
        favoritesStops = Array(favoriteslines.keys)
            .sorted { Int($0)! < Int($1)! }
    }
}
