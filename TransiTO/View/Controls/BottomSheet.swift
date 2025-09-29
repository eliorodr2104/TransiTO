//
//  BottomSheet.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 14/09/25.
//

import SwiftUI

struct BottomSheet: View {
    
    @EnvironmentObject private var arrivalsViewModel  : ArrivalsViewmodel
    @EnvironmentObject private var navigationViemModel: NavigationViewModel
    @EnvironmentObject private var stopsViewModel     : GTFSStaticViewModel
    
    @FocusState private var isFocused: Bool
    
    @State private var fetchTask: Task<Void, Never>? = nil
        
    @Binding var sheetDetent: PresentationDetent
    
    var body: some View {
        
        // Scroll view
        ScrollView(.vertical) {
            bodyBottomSheet
        }
        .simultaneousGesture(DragGesture().onChanged { _ in if isFocused { isFocused = false } })
        .safeAreaInset(edge: .top, spacing: 10) { headerBottomSheet }
        /// Animation focus changes
        .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isFocused)
        /// Updating size when text field is active
        .onChange(of: isFocused) { _, newValue in
            if self.stopsViewModel.searchQuery == "" { sheetDetent = newValue ? .large : .height(350) }
        }
        .onChange(of: self.navigationViemModel.lineSelected != nil) { _, hasSelection in
            if hasSelection { sheetDetent = .large }
        }
        .onChange(of: self.stopsViewModel.searchQuery) { _, newValue in
            self.navigationViemModel.changeStateBottomSheet(to: newValue == "" ? .EMPTY_HOME : .SHOW_SEARCH_STOP)
        }
    }
    
    // MARK: - Body bottom sheet
    private var bodyBottomSheet: some View {
        Group {
            switch self.navigationViemModel.stateView {
                
            case .EMPTY_HOME:
                homeBodyBottomSheet // Default when stop selected is nil
                
            case .SHOW_STOPS_INFO:
                // Click stop and show them info, arrives and lines
                if let currentStop = self.navigationViemModel.stopSelected {
                    LinesAvailablesView(stopInfo: currentStop)
                }
                
            case .SHOW_LINE_INFO:
                // TODO Yet implement info line in select stop
                EmptyView()
                
            case .SHOW_SEARCH_STOP:
                ListStopsMatched() {
                    isFocused = false
                    // Delete because is delete current stop
                    //stopsViewModel.searchQuery  = ""
                }
            }
        }
    }
    
    // MARK: - header bottom sheet
    private var headerBottomSheet: some View {
        HStack(alignment: .center, spacing: 10) {
            
            // Title
            titleBottomSheet
        
            // Profile and close button
            actionButton
        }
        .padding(.horizontal, 18)
        .frame(height: 80)
        .padding(.top, 5)
    }
    
    // MARK: - Title bottom sheet
    private var titleBottomSheet: some View {
        
        Group {
            switch self.navigationViemModel.stateView {
            case .EMPTY_HOME, .SHOW_SEARCH_STOP:
                TextField("Search...", text: $stopsViewModel.searchQuery)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.gray.opacity(0.20), in: .capsule)
                    .glassEffect()
                    .focused($isFocused)
                    .padding(.top, 5)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.none)
                
            case .SHOW_STOPS_INFO:
                Spacer()
                titleStop
                    .padding(.leading, 37)
                
            case .SHOW_LINE_INFO:
                titleLine
                Spacer()
            }
        }
    }
    
    // MARK: - Action button header
    private var actionButton: some View {
        Button {
            
            if isFocused || self.stopsViewModel.searchQuery != "" {
                self.stopsViewModel.searchQuery = ""
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
                
                if isFocused || self.navigationViemModel.stateView != .EMPTY_HOME || self.stopsViewModel.searchQuery != "" {
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
    
    // MARK: - Home body for bottom sheet
    private var homeBodyBottomSheet: some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            
            // Tittle list
            Text("Preferiti")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Lazy row contains prefered
            RowFavoritesStops()
                .padding(.leading, 10)
            
        }
        .padding(.horizontal)
    }
    
    // MARK: - Title for select stop
    private var titleStop: some View {
        
        Group {
            // Control stop select is not nil
            if let stopInfo = self.navigationViemModel.stopSelected {
                
                // split name and get only right part
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
                
            } else { EmptyView() }
        }
    }
    
    // MARK: - title for line selected
    private var titleLine: some View {
        
        Group {
            // Control line selected is not nil
            if let currentLine = self.navigationViemModel.lineSelected {
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(currentLine.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(currentLine.direction)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
            } else { EmptyView() }
            
        }
    }
}
