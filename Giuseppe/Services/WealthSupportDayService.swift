import Foundation
import SwiftData
import SwiftUI

@Observable
final class WealthSupportDayService {
    /// 统计天数（直接在 UserDefaults 读写，确保跨组件同步）
    var lookbackDays: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "wealthLookbackDays")
            return v > 0 ? v : 30
        }
        set { UserDefaults.standard.set(newValue, forKey: "wealthLookbackDays") }
    }

    init() {
        _ = lookbackDays
    }

    func calculateSupportDays(
        accounts: [Account],
        transactions: [Transaction]
    ) -> Double {
        let totalAsset = accounts
            .filter(\.includeInTotalAsset)
            .reduce(0) { $0 + $1.displayBalance }

        let days = lookbackDays
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentExpenses = transactions
            .filter { $0.type == .expense && $0.date >= cutoff }
            .reduce(0) { $0 + $1.amount }

        let dailyAvg = centsToDouble(recentExpenses) / Double(max(days, 1))
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

    func statusColor(for days: Double) -> Color {
        switch statusLabel(for: days).color {
        case "danger":  .red
        case "warning": .orange
        case "caution": .yellow
        case "safe":    .green
        case "free":    .teal
        default:        .blue
        }
    }
}
