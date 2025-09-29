//
//  Homeview.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 15/09/25.
//

import SwiftUI
import CoreLocation

struct HomeView: View {
    
    /// Enviroment viewModel
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var navigationViemModel: NavigationViewModel

    /// Variables animation sheet
    @State private var showSheet          : Bool               = true
    @State private var sheetDetent        : PresentationDetent = .height (80)
    @State private var sheetHeight        : CGFloat            = 0
    @State private var animationDuration  : CGFloat            = 0.3
    @State private var toolBarOpacity     : CGFloat            = 1
    @State private var safeAreaBottomInset: CGFloat            = 0

    /// State variables
    @State private var cameraTarget       : CLLocationCoordinate2D? = nil
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            MapView()
                .onChange(of: self.navigationViemModel.stopSelected) { _, newValue in if (newValue != nil) { sheetDetent = .height(350) } }
                .sheet(isPresented: $showSheet) {
                    
                    BottomSheet(
                        sheetDetent: $sheetDetent
                    )
                    .presentationDetents(
                        [.height(80), .height(350), .large],
                        selection: $sheetDetent
                    )
                    .presentationBackgroundInteraction(.enabled)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onGeometryChange(for: CGFloat.self) {
                        max(min($0.size.height, 400 + safeAreaBottomInset), 0)
                            
                    } action: { oldValue, newValue in
                        let safeArea = 350 + safeAreaBottomInset
                        
                        /// Limit opacity to 300
                        sheetHeight = min(newValue, safeArea)
                        
                        /// Calculate opacity
                        let progress = max(min((newValue - safeArea) / 50, 1), 0)
                        toolBarOpacity = 1 - progress
                            
                        /// Calcule animation velocity
                        let diff = abs(newValue - oldValue)
                        let duration = max(min(diff / 100, 0.3), 0)
                            
                        animationDuration = duration
                    }
                    .ignoresSafeArea()
                    .interactiveDismissDisabled()
                }
                .overlay(alignment: .bottomTrailing) {
                    BottomFloatinToolBar()
                        .padding(.trailing, 15)
                }
                .onGeometryChange(for: CGFloat.self) {
                    $0.safeAreaInsets.bottom
                    
                } action: { newValue in
                    safeAreaBottomInset = newValue
                }
        }
    }
    
    @ViewBuilder
    private func BottomFloatinToolBar() -> some View {
        VStack(spacing: 25) {
            Button {
                self.locationManager.setFocusUserLocation()
                
            } label: {
                Image(systemName: "location")
                
            }
        }
        .font(.title3)
        .foregroundStyle(Color.primary)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .glassEffect(.regular, in: .capsule)
        .opacity(toolBarOpacity)
        .offset(y: -(sheetHeight - 25))
        .animation(.interpolatingSpring(duration: animationDuration, bounce: 0, initialVelocity: 0), value: sheetHeight)
    }
}
