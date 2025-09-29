//
//  LineTransportListView.swift
//  TransiTO
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 08/09/25.
//

import SwiftUI

struct LineTransportListView: View {
    @EnvironmentObject var arrivalsViewModel: ArrivalsViewmodel
    @EnvironmentObject var storageFavorite: StorageFavoriteViewmodel
    
    @State private var isLoading: Bool = true
    @State private var fetchTask: Task<Void, Never>? = nil
        
    let nameStop: String
    
    var lines: [Line] {
        storageFavorite.favoritesTransportStop[nameStop] ?? []
    }
    
    var body: some View {
        ZStack {
            
            if !isLoading {
                
                if !lines.isEmpty {
                    List(lines, id: \.self) { currentLine in
                        LineRow(nameStop: nameStop, line: currentLine)
                            .swipeActions {
                                
                                Button(role: .destructive) {
                                    withAnimation {
                                        storageFavorite.removeLine(from: nameStop, lineNumber: currentLine.number)
                                    }
                                    
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                    
                                }
                                
                                Button {
                                    if currentLine.isFocus {
                                        storageFavorite.removeFocusLine(in: nameStop, for: currentLine.number)
                                        
                                    } else {
                                        storageFavorite.setFocusLine(stopId: nameStop, lineNumber: currentLine.number)
                                        
                                    }
                                    
                                } label: {
                                    Label(currentLine.isFocus ? "Unfavorite" : "Favorite", systemImage: currentLine.isFocus ? "star.slash" : "star")
                                }
                                .tint(.yellow)
                                
                            }
                    }
                    .listStyle(.carousel)
                    
                } else {
                    Text("Line favorite is empty")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                }
                
            } else {
                ProgressView()
            }
            
        }
        .navigationTitle(nameStop)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { addLineButton } }
        .onAppear {
            
            if !lines.isEmpty {
                fetchTask = Task {
                    while !Task.isCancelled {
                        await arrivalsViewModel.fetchStopArrivals(for: nameStop)
                        
                        self.isLoading = false
                                                                
                        try? await Task.sleep(nanoseconds: 45_000_000_000)
                                            
                    }
                }
                
            } else {
                isLoading = false
            }
            
        }
        .onDisappear {
            fetchTask?.cancel()
            fetchTask = nil
            
        }
    }
    
    private var addLineButton: some View {
        NavigationLink(destination: AddFavoriteLine(to: nameStop)) {
            Label("Add", systemImage: "plus")
                .labelStyle(.iconOnly)
            
        }
        .accessibilityLabel("Add favorite station")
    }
}
