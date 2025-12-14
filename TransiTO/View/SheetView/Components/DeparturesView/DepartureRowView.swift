//
//  StopStationHome.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI

struct DepartureRowView: View {
    
    // Get current color scheme from devices
    @Environment(\.colorScheme)
    var colorScheme
        
	var arrival    : Arrival?
    let stopCode   : String
    let typeVehicle: TypeVehicle
    let onClick    : (_ direction: String?) -> Void
    
    private var isLoading: Bool {
        return arrival == nil
    }
    
    private var dataToDisplay: Arrival {
        return arrival ?? Arrival.placeHolder
    }
    
    var body: some View {

        VStack(
			alignment: .leading,
			spacing  : 10
		) {
            
            HStack(
				alignment: .firstTextBaseline,
				spacing  : 7
			) {
                Image(systemName: self.typeVehicle.icon)
					.font(.headline)
					.foregroundStyle(
                        self.colorScheme == .dark ? .black : .white
                    )
					.padding(10)
					.background {
						Circle()
							.fill(.tint)
							.stroke(
								.ultraThickMaterial,
								lineWidth: 3
							)
					}
                
                Text("Linea \(self.dataToDisplay.line)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Divider()
            
            HStack {
                Text(self.dataToDisplay.direction.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(self.dataToDisplay.remainingMinutes) min")
					.font(.subheadline)
                    .fontDesign(.rounded)
					// .fontDesign(.monospaced) -> Not pretty font
                    .foregroundStyle(.secondary)
//					.foregroundStyle(
//						arrival.remainingMinutes <= 5 ? .red :
//						arrival.remainingMinutes <= 10 && arrival.remainingMinutes > 5 ? .yellow :
//						.secondary
//					)
            }
            .id(self.dataToDisplay.id)
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .padding(.horizontal)
        .redacted(reason: isLoading ? .placeholder : [])
        .shimmering(active: isLoading)
        .onTapGesture {
            if let current = self.arrival?.direction {
                onClick(current)
            }
        }
        
    }
}

// Estensione per creare l'effetto luccicante
extension View {
    @ViewBuilder
    func shimmering(active: Bool = true, duration: Double = 1.5) -> some View {
        if active {
            self.overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0),
                                    .white.opacity(0.3), // Colore del luccichio
                                    .white.opacity(0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: width * 3, height: height * 3) // Più grande per coprire rotazione
                        .offset(x: -width * 1.5) // Start position
                        .keyframeAnimator(initialValue: 0.0, repeating: true) { content, progress in
                            content
                                .offset(x: width * 3 * progress) // Move across
                        } keyframes: { _ in
                            KeyframeTrack {
                                LinearKeyframe(1.0, duration: duration)
                            }
                        }
                        .blendMode(.screen) // O .overlay a seconda dei gusti
                        .mask(self) // Maschera solo sulla forma della view
                }
            }
        } else {
            self
        }
    }
}
