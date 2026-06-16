import SwiftUI

struct AmountInputView: View {
    @Binding var amountText: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text("¥")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("0", text: $amountText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .keyboardType(.decimalPad)
                .focused(isFocused)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
