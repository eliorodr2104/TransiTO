//
//  RowStopSearch.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 25/09/25.
//

import SwiftUI

struct RowStopSearch: View {
    let stop	 : Stop
    let highlight: String
    let onClick	 : () -> Void
    
    var body: some View {
       
        VStack(alignment: .leading) {
			highlightedText(
				fullText: stop.stopName,
				highlight: highlight
			)
			.font(.subheadline)
			.foregroundStyle(.primary)
            
			highlightedText(
				fullText: stop.stopCode,
				highlight: highlight
			)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture(perform: onClick)
        
    }
    
    @ViewBuilder
    func highlightedText(
		fullText: String,
		highlight: String
	) -> some View {
		
        if highlight.isEmpty {
            Text(fullText)
            
        } else if let range = fullText.range(
			of: highlight,
			options: [.caseInsensitive, .diacriticInsensitive]
		) {
			
            let start = String(fullText[..<range.lowerBound])
            let match = String(fullText[range])
            let end   = String(fullText[range.upperBound...])
            
            Text("\(start)\(Text(match).bold())\(end)")
            
        } else { Text(fullText) }
    }
}
