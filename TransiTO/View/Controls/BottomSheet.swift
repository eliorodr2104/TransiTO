//
//  BottomSheet.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 14/09/25.
//

import SwiftUI

struct BottomSheet: View {
    
    
    @EnvironmentObject private var arrivalsViewModel: ArrivalsViewmodel
    @EnvironmentObject private var navigationViemModel: NavigationViewModel
    
    @FocusState var isFocused: Bool
    
    @Binding var sheetDetent    : PresentationDetent

    @State private var searchText: String = ""
    @State private var fetchTask : Task<Void, Never>? = nil
    
    var body: some View {
        
        // Scroll view for view
        ScrollView(.vertical) {
            
            if let stopInfo = self.navigationViemModel.stopSelected {
                LinesAvailablesView(
                    stopRoutes: stopInfo.routes,
                    stopCode: stopInfo.stopCode
                )
            }
        }
        .task(id: self.navigationViemModel.stopSelected?.id) {
            guard let stopInfo = self.navigationViemModel.stopSelected else { return }
            
            do {
                while !Task.isCancelled {
                    await arrivalsViewModel.fetchStopArrivals(for: stopInfo.stopCode)
                                        
                    try? await Task.sleep(nanoseconds: 45_000_000_000) // 45_000_000_000
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 10) {
            
            HStack(alignment: .center, spacing: 10) {
                
                switch self.navigationViemModel.stateView {
                case .EMPTY_HOME:
                    TextField("Search...", text: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.gray.opacity(0.25), in: .capsule)
                        .focused($isFocused)
                        .padding(.top, 5)
                    
                case .SHOW_STOPS_INFO:
                    Spacer()
                    titleStop
                        .padding(.leading, 37)
                    
                case .SHOW_LINE_INFO:
                    
                    
                }
            
                /// Profile and close button
                
                Button {
                    
                    if isFocused {
                        isFocused = false
                        
                    } else {
                        /* Action profile button */
                    
                    }
                    
                    if let _ = self.navigationViemModel.stopSelected {
                        fetchTask?.cancel()
                        fetchTask = nil
                        self.navigationViemModel.clear()
                        
                        sheetDetent = .height(80)
                        
                    }

                } label: {
                    ZStack {
                        
                        if isFocused || self.navigationViemModel.stopSelected != nil {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .frame(width: 48, height: 48)
                                .glassEffect(in: .circle)
                                .transition(.blurReplace)
                            
                        } else {
                            Text("ER")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(.gray, in: .circle)
                                .transition(.blurReplace)
                            
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 80)
            .padding(.top, 5)
            
        }
        /// Animation focus changes
        .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isFocused)
        /// Updating size when text field is active
        .onChange(of: isFocused) { oldValue, newValue in
            sheetDetent = newValue ? .large : .height(350)
        }
    }
    
    private var titleStop: some View {
        Group {
            if let stopInfo = self.navigationViemModel.stopSelected {
                let name = stopInfo.stopName.split(separator: " - ", maxSplits: 1, omittingEmptySubsequences: true)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .last ?? stopInfo.stopName
                                                
                VStack(alignment: .center, spacing: 5) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Stop: \(stopInfo.stopCode)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
            } else {
                EmptyView()
                
            }
        }
    }
    
    private var titleLine: some View {
            
        if let line = self.navigationViemModel.lineSelected {
            return VStack(alignment: .leading, spacing: 5) {
                Text(line)
                    .font(.headline)
                    .fontWeight(.bold)
                
//                Text("Stop: \(stopInfo.stopCode)")
//                    .font(.footnote)
//                    .foregroundStyle(.secondary)
                
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        
    }
}
