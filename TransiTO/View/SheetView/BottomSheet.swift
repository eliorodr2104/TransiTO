//
//  BottomSheet.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 14/09/25.
//

import SwiftUI

struct BottomSheet: View {
    
    @EnvironmentObject
	private var gtfsStaticViewModel: GTFSStaticViewModel
	
	@ObservedObject
	var navigationViewModel: NavigationViewModel
	
	@ObservedObject
	var locationManager: LocationManager
    
    @FocusState
	private var isFocused: Bool
    
    @State
	private var fetchTask: Task<Void, Never>? = nil
        
    @Binding
	var sheetDetent: PresentationDetent
    
    var body: some View {
        
        // Scroll view
		ScrollView(.vertical) {
			BodySheet(
				navigationViewModel: self.navigationViewModel,
				locationManager	   : self.locationManager,
				isFocused		   : self.$isFocused,
				sheetDetent		   : self.$sheetDetent
			)
		}
        .simultaneousGesture(
			DragGesture().onChanged { _ in if isFocused { isFocused = false } }
		)
        .safeAreaInset(
			edge: .top,
			spacing: 10
		) { headerBottomSheet }
        .animation(
			.interpolatingSpring(
				duration: 0.3,
				bounce: 0,
				initialVelocity: 0
			),
			value: isFocused
		)
        .onChange(
			of: isFocused,
			handleFocusChange
		)
        .onChange(
			of: self.navigationViewModel.lineSelected,
			handleLineSelectedChange
		)
        .onChange(
			of: self.gtfsStaticViewModel.searchQuery,
			handleSearchQueryChange
		)
    }
    
    // MARK: - Views
    
	/// header bottom sheet
	private var headerBottomSheet: some View {
		
		ZStack {
			BackdropBlurView(radius: 6)
			
			HStack {
				
				// Title
				titleBottomSheet()
				
				Spacer()
			
				// Profile and close button
				actionButton
			}
			.padding(.horizontal, 18)
			.padding(.top, 12)
			
		}
		.frame(height: 80)
		
	}
    
    /// Title bottom sheet
	@ViewBuilder
    private func titleBottomSheet() -> some View {
        
		switch self.navigationViewModel.stateView {
			case .home, .searchStop:
				TextField(
					"Search...",
					text: self.$gtfsStaticViewModel.searchQuery
				)
				.padding(.horizontal, 20)
				.padding(.vertical, 12)
				.background(.gray.opacity(0.20), in: .capsule)
				.glassEffect()
				.focused($isFocused)
				.padding(.top, 5)
				.autocorrectionDisabled(true)
				.textInputAutocapitalization(.none)
				
			case .stopInfo:
				titleStop()
				
			case .departuresInfo:
				titleLine()
				Spacer()
				
			case .addFavorite:
				Spacer()
				titleAddStop.padding(.leading, 37)
		}
    }
    
    /// Action button header
    private var actionButton: some View {
        Button {
			
			switch self.navigationViewModel.stateView {
				case .stopInfo:
					self.fetchTask?.cancel()
					self.fetchTask = nil
					
					self.sheetDetent = .height(80)
					self.navigationViewModel.clear()
					
				case .departuresInfo:
					self.navigationViewModel.stateView = .stopInfo
					
				case .searchStop, .home, .addFavorite:
					if self.isFocused ||
					   !self.gtfsStaticViewModel.searchQuery.isEmpty {
						
						self.gtfsStaticViewModel.searchQuery = ""
						self.isFocused = false
						
						self.sheetDetent = .height(350)
					}
					
					self.navigationViewModel.clear()
					
			}

        } label: {
            ZStack {
                
				if self.isFocused ||
				   self.navigationViewModel.stateView != .home ||
				   !self.gtfsStaticViewModel.searchQuery.isEmpty {
					
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
    
    /// Title for select stop
	@ViewBuilder
	private func titleStop() -> some View {
        
		// Control stop select is not nil
		if let stopInfo = self.navigationViewModel.stopSelected {
			
			HStack {
				Text("\(stopInfo.stopCode)")
					.font(.headline)
					.fontDesign(.monospaced)
					.foregroundStyle(.secondary)
					.padding(.vertical, 13)
					.padding(.leading, 10)
					.padding(.trailing, 5)
				
				Rectangle()
					.frame(
						width: 4,
						height: 39
					)
					.clipShape(.capsule)
 					.padding(.trailing, 5)
					.foregroundStyle(.gray.opacity(0.18))
					
				Text(stopInfo.stopName)
					.font(.headline)
					.fontWeight(.bold)
					.fontDesign(.rounded)
					.lineLimit(2)
				
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			
		} else { EmptyView() }
    }
    
    /// title for line selected
	@ViewBuilder
    private func titleLine() -> some View {
        
		// Control line selected is not nil
		if let vehicle = self.navigationViewModel.lineSelected {
			
			HStack {
				Image(systemName: vehicle.type.icon)
					.font(.headline)
					.fontDesign(.monospaced)
					.foregroundStyle(.secondary)
					.padding(.vertical, 13)
					.padding(.leading, 10)
					.padding(.trailing, 5)
				
				Rectangle()
					.frame(
						width: 4,
						height: 39
					)
					.clipShape(.capsule)
					.padding(.trailing, 5)
					.foregroundStyle(.gray.opacity(0.18))
				
				VStack(alignment: .leading, spacing: 5) {
					Text("Linea \(vehicle.line)")
						.font(.headline)
						.fontWeight(.bold)
						.fontDesign(.rounded)
					
					Text(vehicle.direction)
						.font(.caption)
						.foregroundStyle(.secondary)
						.fontDesign(.rounded)
					
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			
		} else { EmptyView() }
    }
    
    /// Title add favorite stop
    private var titleAddStop: some View {
        
		HStack {
			Text("Aggiungi fermata")
				.font(.headline)
				.fontWeight(.bold)
				.fontDesign(.rounded)
			
		}
    }
	
	// MARK: - Handlers
	
	private func handleFocusChange(
		_ oldValue: Bool,
		_ newValue: Bool
	) {
		if self.gtfsStaticViewModel.searchQuery == "" {
			sheetDetent = newValue ? .large : .height(350)
		}
	}
	
	private func handleLineSelectedChange(
		_ oldValue: Vehicle?,
		_ newValue: Vehicle?
		
	) { if newValue != nil { sheetDetent = .large } }
	
	private func handleSearchQueryChange(
		_ oldValue: String,
		_ newValue: String
	) {
		if self.navigationViewModel.stateView == .home {
			self.navigationViewModel.changeStateBottomSheet(
				to: newValue.isEmpty ? .home : .searchStop
			)
		}
	}
}
