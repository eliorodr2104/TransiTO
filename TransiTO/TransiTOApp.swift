//
//  TransiTOApp.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 23/09/25.
//

import SwiftUI

@main
struct TransiTO_iOSApp: App {
    
    @StateObject private var gtfsStaticViewModel = GTFSStaticViewModel()

    // Body app
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gtfsStaticViewModel)
        }
    }
}
