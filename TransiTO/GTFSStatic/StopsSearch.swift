//
//  StopsSearch.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 25/09/25.
//

import Foundation

final class StopsSearchIndexService {

    private actor IndexState {
        var stops          : [Stop] 		    = []
        var normalizedNames: [String]           = []
        var trigramIndex   : [String: Set<Int>] = [:]
        var codeMap        : [String: Stop]     = [:]
        var codeToIndex    : [String: Int]      = [:]
        var usageCount     : [Int: Int]         = [:]

        func snapshot() -> (
            stops          : [Stop],
            normalizedNames: [String],
            trigramIndex   : [String: Set<Int>],
            codeMap        : [String: Stop],
            codeToIndex    : [String: Int],
            usageCount     : [Int: Int]
        ) {
            
            // Snapshot no-async
            return (
				stops,
				normalizedNames,
				trigramIndex,
				codeMap,
				codeToIndex,
				usageCount
			)
        }

        func replaceIndex(
            stops          : [Stop],
            normalizedNames: [String],
            trigramIndex   : [String: Set<Int>],
            codeMap        : [String: Stop],
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

    /// Construct index, call before with load the Stop in GTFS.
    /// This func is `async`, but is intern and use Task.detached for hard work.
    func build(from stopsArray: [Stop]) async {
        
        // Clear event after build
        buildTask?.cancel()

        // Get local copy for use in detached task
        let snapshotStops = stopsArray

        // Launch hard work in background without get `self`
        buildTask = Task.detached(priority: .userInitiated) {
            
            // local helper
            func normalize(_ string: String) -> String {
				
                let folded = string.folding(
					options: [.diacriticInsensitive, .widthInsensitive]
					, locale: .current
				)
				
                let lower  = folded.lowercased()
                let parts  = lower.components(
					separatedBy: CharacterSet.alphanumerics.inverted
				)
                
				return parts.filter {
					!$0.isEmpty
				}.joined(separator: " ")
				 .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            func trigrams(of string: String) -> [String] {
                if string.count < 3 { return [string] }
                
                let pad = "  " + string + "  "

                let chars = Array(pad)
                var res: [String] = []
                
				for i in 0 ..< (chars.count - 2) {
					res.append(String(chars[i ... i + 2]))
				}
                
                return res
            }

            var localNames: [String] = Array(
				repeating: "",
				count: snapshotStops.count
			)
			
            var localTrigram: [String: Set<Int>] = [:]
            var localCodeMap: [String: Stop] = [:]
            var localCodeToIndex: [String: Int] = [:]

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
        
    ) async -> [Stop] {
        
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
                let folded = string.folding(
					options: [.diacriticInsensitive, .widthInsensitive],
					locale: .current
				)
				
                let lower = folded.lowercased()
                let parts = lower.components(
					separatedBy: CharacterSet.alphanumerics.inverted
				)
                
				return parts.filter {
					!$0.isEmpty
				}.joined(separator: " ")
				 .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            func trigrams(of string: String) -> [String] {
                if string.count < 3 { return [string] }
                let pad = "  " + string + "  "
                
                let chars = Array(pad)
                var res: [String] = []
                
				for i in 0 ..< (chars.count - 2) {
					res.append(String(chars[i ... i + 2]))
				}
                
                return res
            }
            
            func levenshtein(
				_ a: String,
				_ b: String
			) -> Int {
				
				if abs(a.count - b.count) > 4 { return 100 }
				
				let aCount = a.utf8.count
				let bCount = b.utf8.count
							
				if aCount == 0 { return bCount }
				if bCount == 0 { return aCount }
							
				var prev = ContiguousArray<Int>(0...bCount)
				var cur = ContiguousArray<Int>(repeating: 0, count: bCount + 1)
				let aChars = Array(a.utf8)
				let bChars = Array(b.utf8)
							
				for i in 1...aCount {
					cur[0] = i
					
					for j in 1...bCount {
						let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
						cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
					}
					
					swap(&prev, &cur)
				}
				
				return prev[bCount]
            }

            let q = normalize(trimmed)
            
            // first, exact code lookup
            var extraResults: [Stop] = []
            if let byCode = snap.codeMap[q] {
                extraResults.append(byCode)
            }

            // second, candidate reduction via trigram intersection
            let tris = trigrams(of: q)
            var candidateIds = Set<Int>()
            
			if !tris.isEmpty {
				var counts: [Int: Int] = [:]
							
				for t in tris {
					if let set = snap.trigramIndex[t] {
						for id in set {
							counts[id, default: 0] += 1
						}
					}
				}
				
				let threshold = max(1, Int(Double(tris.count) * 0.6))
							
				for (id, count) in counts {
					if count >= threshold {
						candidateIds.insert(id)
					}
				}
            }
			
			let idsToScore = Array(candidateIds)
			
			var scored: [(Int, Double)] = []
			
			for id in idsToScore {
				let name = snap.normalizedNames[id]
				let stop = snap.stops[id]
				var score = 0.0
				
				// Bonus fissi
				if name == q { score += 3000 }
				if name.hasPrefix(q) { score += 2000 + Double(q.count * 10) }
				if name.contains(q) { score += 1200 }

				// Penalità distanza (Levenshtein ottimizzato)
				let dist = levenshtein(q, name)
				// Normalizziamo in base alla lunghezza per non penalizzare parole lunghe
				let maxLen = Double(max(1, max(q.count, name.count)))
				let normDist = Double(dist) / maxLen
						
				// Score basato sulla somiglianza (massimo 800 punti)
				score += max(0, 800 * (1.0 - normDist))

				// Bonus codice parziale
				if stop.stopCode.lowercased().contains(trimmed.lowercased()) {
					score += 400
				}

				// Bonus usage (frequenza d'uso)
				if let u = snap.usageCount[id] {
					score += Double(min(u, 200)) * 0.5
				}
				
				scored.append((id, score))
			}

			let top = scored
				.sorted { $0.1 > $1.1 }
				.prefix(maxResults)
				.map { snap.stops[$0.0] }
				
			let filteredTop = top.filter { stop in
				!extraResults.contains(where: { $0.stopCode == stop.stopCode })
			}
						
			return extraResults + Array(filteredTop.prefix(maxResults - extraResults.count))
        }.value
    }

    /// Record use, this write inside the actor.
    func recordUsage(of stop: Stop) async {
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
