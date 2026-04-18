import SwiftUI

struct QuantityField: View {
    @Binding var quantity: Double
    @Binding var unit: String

    var body: some View {
        HStack {
            TextField("Qty", value: $quantity, format: .number)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
            TextField("unit", text: $unit)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
        }
    }
}
