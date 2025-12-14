//
//  BackdropView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 27/11/25.
// Posted by Dmitrii Guliagin, modified by community. See post 'Timeline' for change history
// Retrieved 2025-11-27, License - CC BY-SA 4.0

import SwiftUI


/// A View in which content reflects all behind it
struct BackdropView: UIViewRepresentable {
	
	func makeUIView(context: Context) -> UIVisualEffectView {
		let view 	 = UIVisualEffectView()
		let blur	 = UIBlurEffect()
		let animator = UIViewPropertyAnimator()
		
		animator.addAnimations { view.effect = blur }
		animator.fractionComplete = 0
		animator.stopAnimation(false)
		animator.finishAnimation(at: .current)
		
		return view
	}
	
	func updateUIView(_ uiView: UIVisualEffectView, context: Context) { }
}

/// A transparent View that blurs its background
struct BackdropBlurView: View {
	
	let radius: CGFloat
	
	@ViewBuilder
	var body: some View {
		BackdropView()
            .blur(radius: radius)
	}
}
