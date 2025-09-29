//
//  ContentView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var arrivalsViewModel  : ArrivalsViewmodel
    @EnvironmentObject private var gtfsStaticViewModel: GTFSStaticViewModel
    
    var body: some View {
        
        ZStack(alignment: .center) {
            
            HomeView()
                .disabled(gtfsStaticViewModel.isLoading)
            
            if gtfsStaticViewModel.isLoading {
                LoadingPopUp()
            }
                
        }
    }
}

#Preview {
    ContentView()
}
