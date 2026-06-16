import XCTest
@testable import Giuseppe

final class WealthSupportDayServiceTests: XCTestCase {
    let service = WealthSupportDayService()

    func testCalculateSupportDays_withTransactions_returnsCorrectValue() {
        let accounts = [
            makeAccount(name: "储蓄卡", balance: 10000_00, include: true),
        ]
        let txns = [
            makeTransaction(amount: 100_00, type: "expense", daysAgo: 0),
            makeTransaction(amount: 200_00, type: "expense", daysAgo: 1),
            makeTransaction(amount: 300_00, type: "expense", daysAgo: 2),
        ]
        service.lookbackDays = 3

        let result = service.calculateSupportDays(accounts: accounts, transactions: txns)
        XCTAssertEqual(result, 50.0, accuracy: 0.1)
    }

    func testCalculateSupportDays_noExpenses_returnsMax() {
        let accounts = [makeAccount(name: "储蓄卡", balance: 5000_00, include: true)]
        let result = service.calculateSupportDays(accounts: accounts, transactions: [])
        XCTAssertEqual(result, 9999.0, accuracy: 0.1)
    }

    func testStatusLabel_ranges() {
        let cases: [(Double, String)] = [
            (400, "🟢 财务自由可期"),
            (200, "🟢 很安全"),
            (120, "🟡 较安全"),
            (60,  "🟠 需要注意"),
            (10,  "🔴 警戒"),
        ]
        for (days, expected) in cases {
            XCTAssertEqual(service.statusLabel(for: days).text, expected)
        }
    }

    private func makeAccount(name: String, balance: Int, include: Bool) -> Account {
        Account(name: name, type: "bank", balance: balance, includeInTotalAsset: include)
    }

    private func makeTransaction(amount: Int, type: String, daysAgo: Int) -> Transaction {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return Transaction(amount: amount, type: type, categoryId: UUID(), accountId: UUID(), date: date)
    }
}
