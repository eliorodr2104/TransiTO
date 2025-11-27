//
//  StopsSearch.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 25/09/25.
//

import Foundation

/// Final class pubblica che fornisce build/search/usage senza catturare MainActor self.
final class StopsSearchIndexService {

    private actor IndexState {
        var stops          : [AllInfoStop]         = []
        var normalizedNames: [String]              = []
        var trigramIndex   : [String: Set<Int>]    = [:]
        var codeMap        : [String: AllInfoStop] = [:]
        var codeToIndex    : [String: Int]         = [:]
        var usageCount     : [Int: Int]            = [:]

        func snapshot() -> (
            stops          : [AllInfoStop],
            normalizedNames: [String],
            trigramIndex   : [String: Set<Int>],
            codeMap        : [String: AllInfoStop],
            codeToIndex    : [String: Int],
            usageCount     : [Int: Int]
        ) {
            
            // Snapshot no-async
            return (stops, normalizedNames, trigramIndex, codeMap, codeToIndex, usageCount)
        }

        func replaceIndex(
            stops          : [AllInfoStop],
            normalizedNames: [String],
            trigramIndex   : [String: Set<Int>],
            codeMap        : [String: AllInfoStop],
            codeToIndex    : [String: Int]
        ) {
            
            self.stops           = stops
            self.normalizedNames = normalizedNames
            self.trigramIndex    = trigramIndex
            self.codeMap         = codeMap
            self.codeToIndex     = codeToIndex
        }

        func incrementUsage(forIndex index: Int) {
            usageCount[index, default: 0] += 1
        }
    }

    private let state = IndexState()
    private var buildTask: Task<Void, Never>?

    init() { }

    /// Construct index, call before with load the AllInfoStop in GTFS.
    /// This func is `async`, but is intern and use Task.detached for hard work.
    func build(from stopsArray: [AllInfoStop]) async {
        
        // Clear event after build
        buildTask?.cancel()

        // Get local copy for use in detached task
        let snapshotStops = stopsArray

        // Launch hard work in background without get `self`
        buildTask = Task.detached(priority: .userInitiated) {
            
            // local helper
            func normalize(_ string: String) -> String {
                let folded = string.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
                let lower  = folded.lowercased()
                let parts  = lower.components(separatedBy: CharacterSet.alphanumerics.inverted)
                
                return parts.filter { !$0.isEmpty }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            }

            func trigrams(of string: String) -> [String] {
                if string.count < 3 { return [string] }
                
                let pad = "  " + string + "  "

                let chars = Array(pad)
                var res: [String] = []
                
                for i in 0 ..< (chars.count - 2) { res.append(String(chars[i ... i + 2])) }
                
                return res
            }

            var localNames      : [String]              = Array(repeating: "", count: snapshotStops.count)
            var localTrigram    : [String: Set<Int>]    = [:]
            var localCodeMap    : [String: AllInfoStop] = [:]
            var localCodeToIndex: [String: Int]         = [:]

            for (i, stop) in snapshotStops.enumerated() {
                if Task.isCancelled { return } // delete coop
                
                let nameNorm = normalize(stop.stopName)
                
                localNames[i] = nameNorm
                localCodeMap[normalize(stop.stopCode)] = stop
                localCodeToIndex[stop.stopCode] = i

                let tris = Set(trigrams(of: nameNorm))
                for t in tris { localTrigram[t, default: []].insert(i)  }
            }

            // Then create local dict, passed in actor for atomic mode
            await self.state.replaceIndex(
                stops          : snapshotStops,
                normalizedNames: localNames,
                trigramIndex   : localTrigram,
                codeMap        : localCodeMap,
                codeToIndex    : localCodeToIndex
            )
        }

        await buildTask?.value
    }

    /// Find query, this func is async and return results.
    /// Intern: Get snapshot in actor and calc ranking in background.
    func search(
        _ rawQuery: String,
        maxResults: Int = 50
        
    ) async -> [AllInfoStop] {
        
        // get snapshot in index
        let snap = await state.snapshot()

        // if index empty then return empty
        guard !snap.stops.isEmpty else { return [] }

        // if query empty then return empty
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // start search on separate tasx
        return await Task.detached(priority: .userInitiated) {
            
            // helpers
            func normalize(_ string: String) -> String {
                let folded = string.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
                let lower = folded.lowercased()
                let parts = lower.components(separatedBy: CharacterSet.alphanumerics.inverted)
                
                return parts.filter { !$0.isEmpty }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            func trigrams(of string: String) -> [String] {
                if string.count < 3 { return [string] }
                let pad = "  " + string + "  "
                
                let chars = Array(pad)
                var res: [String] = []
                
                for i in 0 ..< (chars.count - 2) { res.append(String(chars[i ... i + 2])) }
                
                return res
            }
            
            func levenshtein(_ a: String, _ b: String) -> Int {
                let A = Array(a)
                let B = Array(b)
                let n = A.count
                let m = B.count
                
                if n == 0 { return m }
                if m == 0 { return n }
                
                var prev = Array(0...m)
                var cur = Array(repeating: 0, count: m+1)
                
                for i in 1 ... n {
                    cur[0] = i
                    
                    for j in 1 ... m {
                        let cost = A[i-1] == B[j-1] ? 0 : 1
                        cur[j] = min(prev[j] + 1, cur[j-1] + 1, prev[j-1] + cost)
                    }
                    
                    swap(&prev, &cur)
                }
                
                return prev[m]
            }

            let q = normalize(trimmed)
            
            // first, exact code lookup
            var extraResults: [AllInfoStop] = []
            if let byCode = snap.codeMap[q] {
                extraResults.append(byCode)
            }

            // second, candidate reduction via trigram intersection
            let tris = trigrams(of: q)
            var candidateIds = Set<Int>()
            
            if let first = tris.first, let set = snap.trigramIndex[first] {
                candidateIds = set
                
                for tri in tris.dropFirst() {
                    
                    if let s = snap.trigramIndex[tri] {
                        candidateIds.formIntersection(s)
                        
                    } else {
                        candidateIds = []
                        break
                        
                    }
                    
                    if candidateIds.isEmpty { break }
                }
            }

            // union
            if candidateIds.isEmpty {
                
                for item in tris {
                    if let string = snap.trigramIndex[item] {
                        candidateIds.formUnion(string)
                        
                    }
                }
            }

            // if still empty, use all
            let useAll = candidateIds.isEmpty
            let idsToScore: [Int] = useAll ? Array(0..<snap.stops.count) : Array(candidateIds)

            // scoring
            var scored: [(Int, Double)] = []
            for id in idsToScore {
                let name = snap.normalizedNames[id]
                let stop = snap.stops[id]
                var score = 0.0

                if name == q { score += 3000 }
                if name.hasPrefix(q) { score += 2000 + Double(q.count * 10) }
                if name.contains(q) { score += 1200 }

                let dist = levenshtein(q, name)
                let normDist = Double(dist) / Double(max(1, max(q.count, name.count)))
                score += max(0, 800 * (1.0 - normDist))

                if stop.stopCode.lowercased().contains(trimmed.lowercased()) { score += 400 }

                if let u = snap.usageCount[id] { score += Double(min(u, 200)) * 0.5 }

                scored.append((id, score))
            }

            let top = scored.sorted { $0.1 > $1.1 }.prefix(maxResults).map { snap.stops[$0.0] }
            
            let filteredTop = top.filter { stop in
                !extraResults.contains(where: { $0.stopCode == stop.stopCode })
            }
                        
            return extraResults + Array(filteredTop.prefix(maxResults - extraResults.count))
            
        }.value
    }

    /// Record use, this write inside the actor.
    func recordUsage(of stop: AllInfoStop) async {
        // get index, if present and increment
        let snap = await state.snapshot()
        
        if let idx = snap.codeToIndex[stop.stopCode] {
            await state.incrementUsage(forIndex: idx)
            
        }
    }

    /// Delete build in progress
    func cancelBuild() {
        buildTask?.cancel()
        buildTask = nil
        
    }
}
