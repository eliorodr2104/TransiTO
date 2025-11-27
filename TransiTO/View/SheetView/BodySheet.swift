//
//  BodySheet.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 26/11/25.
//

import SwiftUI

struct BodySheet: View {
	
	@ObservedObject
	var navigationViewModel: NavigationViewModel
	
	@ObservedObject
	var locationManager: LocationManager
	
	@StateObject
	private var arrivalsViewModel = ArrivalsViewModel()
	
	@StateObject
	private var favoritesViewModel = FavoritesViewModel()
	
	var isFocused: FocusState<Bool>.Binding
	
	@Binding
	var sheetDetent: PresentationDetent
	
	var body: some View {
		switch self.navigationViewModel.stateView {
			
			case .home:
				homeBodyBottomSheet // Default when stop selected is nil
				
			case .stopInfo:
				// Click stop and show them info, arrives and lines
				if let currentStop = self.navigationViewModel.stopSelected {
					LinesAvailablesView(
						viewModel: self.arrivalsViewModel,
						changeLineFocus: self.navigationViewModel.changeLineFocus,
						stopInfo: currentStop
					)
				}
				
			case .lineInfo:
				// Show current arrival state
				if let lineSelected = navigationViewModel.lineSelected,
				   let stopSelected = navigationViewModel.stopSelected {
					
					ArrivalsView(
						arrivalsViewModel: self.arrivalsViewModel,
						lineSelected	 : lineSelected,
						stopSelected	 : stopSelected
					)
				}
				
			case .searchStop:
				ListStopsMatched(
					navigationViewModel: self.navigationViewModel,
					locationManager	   : self.locationManager,
					
				) { self.isFocused.wrappedValue = false }
				
			case .addFavorite:
				SearchFavoriteStopView(
					favoritesViewModel : self.favoritesViewModel,
					navigationViewModel: self.navigationViewModel,
					sheetDetent		   : self.$sheetDetent
				)
		}
	}
	
	/// Home body for bottom sheet
	private var homeBodyBottomSheet: some View {
		VStack(
			alignment: .leading,
			spacing: 10
		) {
			
			// Title list
			Text("Preferiti")
				.font(.title3)
				.fontWeight(.bold)
				.foregroundStyle(.primary)
			
			// Lazy row contains prefered
			RowFavoritesStops(
				favoritesViewModel: self.favoritesViewModel,
				locationManager   : self.locationManager,
				sheetDetent		  : self.$sheetDetent
			
			) {
				self.isFocused.wrappedValue = true
				self.navigationViewModel.changeStateBottomSheet(to: .addFavorite)
			}
			.padding(.leading, 10)
			
		}
		.padding(.horizontal)
	}	
}
