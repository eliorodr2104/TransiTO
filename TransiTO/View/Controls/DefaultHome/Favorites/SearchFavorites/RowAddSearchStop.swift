//
//  RowSearchStop.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 04/10/25.
//

import SwiftUI

struct RowAddSearchStop: View {
    let stop     : AllInfoStop
    let highlight: String
    let onClick  : () -> Void
    
    var body: some View {
        let splitStopInfo = stop.stopName.split(separator: " - ")
        let name = String(splitStopInfo.last ?? "NIL")
        let code = String(splitStopInfo.first ?? "NIL")
        
        VStack(alignment: .leading) {
            highlightedText(fullText: name, highlight: highlight)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            highlightedText(fullText: code, highlight: highlight)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture(perform: onClick)
        
    }
    
    @ViewBuilder
    func highlightedText(fullText: String, highlight: String) -> some View {
        if highlight.isEmpty {
            Text(fullText)
            
        } else if let range = fullText.range(of: highlight, options: [.caseInsensitive, .diacriticInsensitive]) {
            let start = String(fullText[..<range.lowerBound])
            let match = String(fullText[range])
            let end = String(fullText[range.upperBound...])
            
            Text("\(start)\(Text(match).bold())\(end)")
            
        } else {
            Text(fullText)
            
        }
    }
}
