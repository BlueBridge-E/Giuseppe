import Foundation

extension NumberFormatter {
    /// 供 formatCents 使用的共享 formatter，访问需加锁
    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    /// 保护 currencyFormatter 的锁（NumberFormatter 非线程安全）
    fileprivate static let formatterLock = NSLock()
}

/// 分 → 格式化字符串（如 1250 → "12.5"），线程安全
func formatCents(_ cents: Int) -> String {
    let yuan = Double(cents) / 100.0
    NumberFormatter.formatterLock.lock()
    defer { NumberFormatter.formatterLock.unlock() }
    return NumberFormatter.currencyFormatter.string(from: NSNumber(value: yuan)) ?? "0"
}

/// 分 → Double（元），如 1250 → 12.5
func centsToDouble(_ cents: Int) -> Double {
    Double(cents) / 100.0
}

/// Double（元）→ 分，如 12.5 → 1250
func yuanToCents(_ yuan: Double) -> Int {
    Int((yuan * 100).rounded())
}
