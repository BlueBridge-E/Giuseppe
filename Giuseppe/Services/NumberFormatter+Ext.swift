import Foundation

extension NumberFormatter {
    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
}

func formatCents(_ cents: Int) -> String {
    let yuan = Double(cents) / 100.0
    return NumberFormatter.currencyFormatter.string(from: NSNumber(value: yuan)) ?? "0"
}

func centsToDouble(_ cents: Int) -> Double {
    Double(cents) / 100.0
}

func yuanToCents(_ yuan: Double) -> Int {
    Int((yuan * 100).rounded())
}
