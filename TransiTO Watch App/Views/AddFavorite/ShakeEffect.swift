//
//  ShakeEffect.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 12/09/25.
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: travelDistance * sin(animatableData * .pi * shakesPerUnit),
            y: 0
        ))
    }
}
