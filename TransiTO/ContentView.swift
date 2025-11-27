//
//  ContentView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI

struct ContentView: View {
	
    @EnvironmentObject
	private var gtfsStaticViewModel: GTFSStaticViewModel
    
    var body: some View {
        
        ZStack(alignment: .center) {
            
            HomeView()
                .disabled(gtfsStaticViewModel.isLoading)
            
            if gtfsStaticViewModel.isLoading { loadingPopUp }
                
        }
    }
	
	private var loadingPopUp: some View {
		VStack {
			ProgressView("Update DataBase...")
				.padding()
				.background(.thinMaterial)
				.cornerRadius(12)
				.shadow(radius: 8)
		}
		.transition(.scale.combined(with: .opacity))
	}
}

#Preview {
    ContentView()
}
