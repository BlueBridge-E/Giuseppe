import Foundation
import SwiftData

@Observable
final class WealthSupportDayService {
    var lookbackDays: Int {
        didSet { UserDefaults.standard.set(lookbackDays, forKey: "wealthLookbackDays") }
    }

    init() {
        lookbackDays = UserDefaults.standard.integer(forKey: "wealthLookbackDays")
        if lookbackDays == 0 { lookbackDays = 30 }
    }

    func calculateSupportDays(
        accounts: [Account],
        transactions: [Transaction]
    ) -> Double {
        let totalAsset = accounts
            .filter(\.includeInTotalAsset)
            .reduce(0) { $0 + $1.displayBalance }

        let cutoff = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: Date()) ?? Date()
        let recentExpenses = transactions
            .filter { $0.type == "expense" && $0.date >= cutoff }
            .reduce(0) { $0 + $1.amount }

        let dailyAvg = centsToDouble(recentExpenses) / Double(max(lookbackDays, 1))
        let totalAssetYuan = centsToDouble(totalAsset)

        guard dailyAvg > 0 else { return totalAssetYuan > 0 ? 9999 : 0 }
        return totalAssetYuan / dailyAvg
    }

    func statusLabel(for days: Double) -> (text: String, color: String) {
        switch days {
        case ..<30:  ("🔴 警戒", "danger")
        case 30..<90: ("🟠 需要注意", "warning")
        case 90..<180: ("🟡 较安全", "caution")
        case 180..<365: ("🟢 很安全", "safe")
        default: ("🟢 财务自由可期", "free")
        }
    }
}
