import SwiftUI
import SwiftUI_Apple_Watch_Decimal_Pad

struct AddFavoriteStation: View {
    
    @EnvironmentObject var storageFavorite: StorageFavoriteViewmodel
    @EnvironmentObject var busStops: TransportStopsViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var stopCode = ""
    @State private var presentingModal = true
    
    @State private var attempts: Int = 0
    @State private var invalid: Bool = false

    var body: some View {
        
        VStack(alignment: .center) {
            
            DigiTextView(
                placeholder: "Number stop",
                text: $stopCode,
                presentingModal: presentingModal,
                alignment: .leading
            )
            .padding(.top, 16)
            .modifier(ShakeEffect(animatableData: CGFloat(attempts)))
            
            Spacer()
        }
        .toolbar {
            if presentingModal {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveStopCode) {
                        
                        Label("Add item", systemImage: "checkmark")
                            .labelStyle(.iconOnly)
                        
                    }
                   
                }
            }
        }
        .navigationTitle("Add Stop")

    }
    
    private func saveStopCode() {
        guard !stopCode.isEmpty else {
            invalid = true
            withAnimation(.default) { attempts += 1 }
            WKInterfaceDevice.current().play(.failure)
            return
        }
        
        guard (busStops.getBusStop(byCode: stopCode) != nil) else {
            invalid = true
            withAnimation(.default) { attempts += 1 }
            WKInterfaceDevice.current().play(.failure)
            return
        }
        
        storageFavorite.addStop(to: stopCode)
        dismiss()
    }
}
