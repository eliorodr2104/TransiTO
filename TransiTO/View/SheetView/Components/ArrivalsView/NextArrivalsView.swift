//
//  ListNextArrivalsView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 29/09/25.
//

import SwiftUI

struct NextArrivalsView: View {
    let remainingTimeArrivals: [Int]
    let arrivals: [Arrival]
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Text("Partenze previste:")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if remainingTimeArrivals.count >= 3 {
                    Spacer()
                    
                    Text("Ogni \(abs(remainingTimeArrivals[1] - remainingTimeArrivals[2])) min")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(remainingTimeArrivals.indices, id: \.self) { index in
                        let item     = remainingTimeArrivals[index]
                        let realtime = index == 0 && arrivals[index].realtime

                        VStack {
                            Text("\(item) min")
                                .font(.headline)
							
                            Text(realtime ? "In orario" : "Programmato")
                                .foregroundStyle(realtime ? Color.accentColor : .secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}
